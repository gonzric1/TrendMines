require "test_helper"

module Api
  module V1
    class ListingsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY')
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

      test "should get alerts" do
        get alerts_api_v1_listings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['message'].present?
      end

      test "should get leaderboard" do
        get leaderboard_api_v1_listings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['message'].present?
      end
    end
  end
end
