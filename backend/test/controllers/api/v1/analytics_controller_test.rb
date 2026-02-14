require "test_helper"

module Api
  module V1
    class AnalyticsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'test-api-key-for-test-suite')
        @headers = { 'X-API-Key' => @api_key }
      end

      # Authentication tests
      test "revenue requires authentication" do
        get api_v1_analytics_revenue_url
        assert_response :unauthorized
      end

      test "funnel requires authentication" do
        get api_v1_analytics_funnel_url
        assert_response :unauthorized
      end

      test "sources requires authentication" do
        get api_v1_analytics_sources_url
        assert_response :unauthorized
      end

      test "costs requires authentication" do
        get api_v1_analytics_costs_url
        assert_response :unauthorized
      end

      # Revenue endpoint tests
      test "revenue returns success with default params" do
        get api_v1_analytics_revenue_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "daily", json["period"]
        assert_not_nil json["total_revenue"]
        assert_not_nil json["data"]
        assert_not_nil json["start_date"]
        assert_not_nil json["end_date"]
      end

      test "revenue supports weekly period" do
        get api_v1_analytics_revenue_url(period: "weekly"), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "weekly", json["period"]
      end

      test "revenue supports monthly period" do
        get api_v1_analytics_revenue_url(period: "monthly"), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "monthly", json["period"]
      end

      test "revenue rejects invalid period" do
        get api_v1_analytics_revenue_url(period: "yearly"), headers: @headers
        assert_response :bad_request

        json = JSON.parse(response.body)
        assert_includes json["error"], "Invalid period"
      end

      test "revenue filters by date range" do
        start_date = 10.days.ago.to_date.to_s
        end_date = Date.current.to_s

        get api_v1_analytics_revenue_url(start_date: start_date, end_date: end_date), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal start_date, json["start_date"]
        assert_equal end_date, json["end_date"]
      end

      test "revenue filters by product_type" do
        get api_v1_analytics_revenue_url(product_type: "vinyl_sticker"), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json["total_revenue"]
      end

      test "revenue filters by product_id" do
        product = products(:frieren_sticker_product)
        get api_v1_analytics_revenue_url(product_id: product.id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json["total_revenue"]
      end

      test "revenue aggregation is correct" do
        get api_v1_analytics_revenue_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        # Sum of all metric_snapshots revenue from fixtures:
        # sticker_recent: 47.88, sticker_older: 31.92, print_recent: 44.97, print_older: 29.98
        expected_total = MetricSnapshot.sum(:revenue).to_f
        assert_in_delta expected_total, json["total_revenue"].to_f, 0.01
      end

      test "revenue handles invalid date gracefully" do
        get api_v1_analytics_revenue_url(start_date: "not-a-date"), headers: @headers
        assert_response :success
      end

      # Funnel endpoint tests
      test "funnel returns all pipeline stages" do
        get api_v1_analytics_funnel_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        stages = json["funnel"].map { |s| s["stage"] }

        assert_includes stages, "total_signals"
        assert_includes stages, "promoted_signals"
        assert_includes stages, "niches"
        assert_includes stages, "tokens_with_designs"
        assert_includes stages, "products"
        assert_includes stages, "active_listings"
        assert_includes stages, "listings_with_sales"
      end

      test "funnel counts are accurate" do
        get api_v1_analytics_funnel_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        funnel = json["funnel"].index_by { |s| s["stage"] }

        assert_equal TrendSignal.count, funnel["total_signals"]["count"]
        assert_equal Niche.count, funnel["niches"]["count"]
        assert_equal Product.count, funnel["products"]["count"]
        assert_equal Listing.where(status: "active").count, funnel["active_listings"]["count"]
      end

      test "funnel returns zero counts not errors when empty" do
        # Even with fixtures, promoted_signals should still be a valid number
        get api_v1_analytics_funnel_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json["funnel"].each do |stage|
          assert_kind_of Integer, stage["count"]
          assert stage["count"] >= 0
        end
      end

      # Sources endpoint tests
      test "sources returns data grouped by source" do
        get api_v1_analytics_sources_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json["sources"]
        assert_kind_of Array, json["sources"]

        # We should have data for each unique source in fixtures
        sources = json["sources"].map { |s| s["source"] }
        assert_includes sources, "twitter"
      end

      test "sources include signal count and revenue" do
        get api_v1_analytics_sources_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json["sources"].each do |source|
          assert_not_nil source["source"]
          assert_not_nil source["signal_count"]
          assert_not_nil source["product_count"]
          assert_not_nil source["total_revenue"]
        end
      end

      test "sources sorted by revenue descending" do
        get api_v1_analytics_sources_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        revenues = json["sources"].map { |s| s["total_revenue"].to_f }
        assert_equal revenues, revenues.sort.reverse
      end

      # Costs endpoint tests
      test "costs returns all cost categories" do
        get api_v1_analytics_costs_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        costs = json["costs"]

        assert_not_nil costs["design_generation"]
        assert_not_nil costs["material_costs"]
        assert_not_nil costs["etsy_transaction_fees"]
        assert_not_nil costs["etsy_listing_fees"]
        assert_not_nil costs["total_estimated"]
        assert_not_nil json["total_revenue"]
      end

      test "costs design generation matches sum of design costs" do
        get api_v1_analytics_costs_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        expected_design_cost = Design.sum(:generation_cost).to_f
        assert_in_delta expected_design_cost, json["costs"]["design_generation"].to_f, 0.01
      end

      test "costs material costs matches sum of product unit costs" do
        get api_v1_analytics_costs_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        expected_material = Product.sum(:unit_cost).to_f
        assert_in_delta expected_material, json["costs"]["material_costs"].to_f, 0.01
      end

      test "costs returns numeric values not errors" do
        get api_v1_analytics_costs_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json["costs"].each do |key, value|
          assert_kind_of Numeric, value, "#{key} should be numeric"
        end
      end
    end
  end
end
