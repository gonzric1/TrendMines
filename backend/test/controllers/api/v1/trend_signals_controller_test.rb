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

      # History endpoint tests

      test "history should require API key" do
        get history_api_v1_trend_signal_url(@signal)
        assert_response :unauthorized
      end

      test "history should return 404 for non-existent signal" do
        get history_api_v1_trend_signal_url(id: 999999), headers: @headers
        assert_response :not_found
      end

      test "history should return response structure" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @signal.id, json['signal_id']
        assert_equal '30d', json['period']
        assert_equal 'daily', json['granularity']
        assert_kind_of Array, json['data']
      end

      test "history data points should have correct keys" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['data'].any?, "Expected data points for signal with snapshots"

        point = json['data'].first
        assert point.key?('date')
        assert point.key?('momentum_score')
        assert point.key?('source_metrics')
      end

      test "history should filter by 7d period" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers,
          params: { period: '7d' }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal '7d', json['period']
        # 7d should exclude the 14d and 30d snapshots
        json['data'].each do |point|
          assert Date.parse(point['date']) >= 7.days.ago.to_date
        end
      end

      test "history should filter by 90d period" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers,
          params: { period: '90d' }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal '90d', json['period']
      end

      test "history should support hourly granularity" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers,
          params: { granularity: 'hourly' }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 'hourly', json['granularity']
        # Hourly format includes hour component
        if json['data'].any?
          assert_match(/\d{4}-\d{2}-\d{2} \d{2}:00/, json['data'].first['date'])
        end
      end

      test "history should support weekly granularity" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers,
          params: { granularity: 'weekly' }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 'weekly', json['granularity']
        # Weekly format includes week number
        if json['data'].any?
          assert_match(/\d{4}-W\d{2}/, json['data'].first['date'])
        end
      end

      test "history should default to 30d/daily for invalid params" do
        get history_api_v1_trend_signal_url(@signal), headers: @headers,
          params: { period: 'invalid', granularity: 'bogus' }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal '30d', json['period']
        assert_equal 'daily', json['granularity']
      end

      test "history should return empty data for signal with no snapshots" do
        signal = trend_signals(:archived_show)
        get history_api_v1_trend_signal_url(signal), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal [], json['data']
      end
    end
  end
end
