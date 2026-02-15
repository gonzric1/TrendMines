require "test_helper"

module Api
  module V1
    class ListingsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'test-api-key-for-test-suite')
        @headers = { 'X-API-Key' => @api_key }
        @listing = listings(:active_sticker_listing)
      end

      test "should require API key" do
        get api_v1_listings_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_listings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should filter by status" do
        get api_v1_listings_url(status: 'active'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |listing|
          assert_equal 'active', listing['status']
        end
      end

      test "should show listing" do
        get api_v1_listing_url(@listing), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @listing.id, json['id']
      end

      test "should create listing" do
        assert_difference('Listing.count') do
          post api_v1_listings_url, headers: @headers, params: {
            listing: {
              product_id: products(:frieren_sticker_product).id,
              title: 'New Listing',
              status: 'draft'
            }
          }
        end

        assert_response :created
      end

      test "should not create listing with invalid params" do
        assert_no_difference('Listing.count') do
          post api_v1_listings_url, headers: @headers, params: {
            listing: { title: nil }
          }
        end

        assert_response :unprocessable_entity
      end

      test "should update listing" do
        patch api_v1_listing_url(@listing), headers: @headers, params: {
          listing: { title: 'Updated Title' }
        }

        assert_response :success
        @listing.reload
        assert_equal 'Updated Title', @listing.title
      end

      test "should pause listing on destroy" do
        delete api_v1_listing_url(@listing), headers: @headers
        assert_response :no_content

        @listing.reload
        assert_equal 'paused', @listing.status
      end

      test "should get listing metrics" do
        get metrics_api_v1_listing_url(@listing), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
      end

      test "should create metric snapshot" do
        assert_difference('MetricSnapshot.count') do
          post metrics_api_v1_listing_url(@listing), headers: @headers, params: {
            metric_snapshot: {
              views: 100,
              favorites: 10,
              sales: 5,
              revenue: 25.50,
              captured_at: Time.current
            }
          }
        end

        assert_response :created
      end

      test "should get alerts with classification data" do
        get alerts_api_v1_listings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
        assert json['meta']['total'].is_a?(Integer)

        json['data'].each do |alert|
          assert alert['listing_id'].present?
          assert alert['alert_type'].present?
          assert_includes %w[first_sale promising no_signal], alert['alert_type']
          assert alert['threshold_crossed'].present?
          assert alert['recommended_action'].present?
        end
      end

      test "should filter alerts by alert_type" do
        get alerts_api_v1_listings_url(alert_type: 'first_sale'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |alert|
          assert_equal 'first_sale', alert['alert_type']
        end
      end

      test "should filter alerts by date range" do
        get alerts_api_v1_listings_url(
          start_date: 2.days.ago.to_date.iso8601,
          end_date: Date.today.iso8601
        ), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
      end

      test "should get leaderboard with default params" do
        get leaderboard_api_v1_listings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
        assert_equal 'revenue', json['meta']['sort_by']
        assert_equal '30d', json['meta']['period']

        json['data'].each_with_index do |entry, idx|
          assert entry['listing_id'].present?
          assert entry['title'].present?
          assert_equal idx + 1, entry['rank']
          assert_includes %w[up down stable], entry['trend']
        end
      end

      test "should get leaderboard sorted by sales" do
        get leaderboard_api_v1_listings_url(sort_by: 'sales'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 'sales', json['meta']['sort_by']

        # Verify sorted descending
        sales_values = json['data'].map { |e| e['sales'] }
        assert_equal sales_values.sort.reverse, sales_values
      end

      test "should reject invalid sort_by" do
        get leaderboard_api_v1_listings_url(sort_by: 'invalid'), headers: @headers
        assert_response :bad_request
      end

      test "should reject invalid period" do
        get leaderboard_api_v1_listings_url(period: 'invalid'), headers: @headers
        assert_response :bad_request
      end

      test "should respect limit param" do
        get leaderboard_api_v1_listings_url(limit: 1), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['data'].size <= 1
      end
    end
  end
end
