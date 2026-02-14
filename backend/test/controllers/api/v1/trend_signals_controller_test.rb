require "test_helper"

module Api
  module V1
    class TrendSignalsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'test-api-key-for-test-suite')
        @headers = { 'X-API-Key' => @api_key }
        @signal = trend_signals(:trending_anime)
      end

      test "should require API key" do
        get api_v1_trend_signals_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_trend_signals_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should show trend signal" do
        get api_v1_trend_signal_url(@signal), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @signal.id, json['id']
      end

      test "should create trend signal" do
        assert_difference('TrendSignal.count') do
          post api_v1_trend_signals_url, headers: @headers, params: {
            trend_signal: {
              source: 'twitter',
              topic: 'New Topic',
              status: 'new'
            }
          }
        end

        assert_response :created
      end

      test "should not create trend signal with invalid params" do
        assert_no_difference('TrendSignal.count') do
          post api_v1_trend_signals_url, headers: @headers, params: {
            trend_signal: { topic: nil }
          }
        end

        assert_response :unprocessable_entity
      end

      test "should update trend signal" do
        patch api_v1_trend_signal_url(@signal), headers: @headers, params: {
          trend_signal: { topic: 'Updated Topic' }
        }

        assert_response :success
        @signal.reload
        assert_equal 'Updated Topic', @signal.topic
      end

      test "should archive trend signal on destroy" do
        delete api_v1_trend_signal_url(@signal), headers: @headers
        assert_response :no_content

        @signal.reload
        assert_equal 'archived', @signal.status
      end
    end
  end
end
