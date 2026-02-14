require "test_helper"

module Api
  module V1
    class SettingsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch("API_KEY", "test-api-key-for-test-suite")
        @headers = { "X-API-Key" => @api_key }
      end

      # Authentication

      test "should require authentication for index" do
        get api_v1_settings_url
        assert_response :unauthorized
      end

      test "should require authentication for update" do
        patch api_v1_settings_url, params: { settings: {} }
        assert_response :unauthorized
      end

      test "should require authentication for api_keys" do
        get api_v1_settings_api_keys_url
        assert_response :unauthorized
      end

      test "should require authentication for test_connection" do
        post api_v1_settings_test_connection_url
        assert_response :unauthorized
      end

      # GET /settings

      test "index returns settings grouped by category" do
        get api_v1_settings_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json.key?("scanning")
        assert json.key?("api_keys")
      end

      test "index returns setting keys and values" do
        get api_v1_settings_url, headers: @headers
        json = JSON.parse(response.body)

        scanning = json["scanning"]
        assert_kind_of Array, scanning

        setting = scanning.find { |s| s["key"] == "scanning.ao3_frequency" }
        assert_not_nil setting
        assert_equal 12, setting["value"]
        assert_not_nil setting["description"]
      end

      test "index returns api_keys status without values" do
        get api_v1_settings_url, headers: @headers
        json = JSON.parse(response.body)

        api_keys = json["api_keys"]
        assert_kind_of Array, api_keys
        api_keys.each do |key_entry|
          assert key_entry.key?("configured")
          assert_not key_entry.key?("value"), "API keys should not expose values"
        end
      end

      # PATCH /settings

      test "update changes setting values" do
        patch api_v1_settings_url, headers: @headers, params: {
          settings: { "scanning.ao3_frequency" => 24 }
        }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_includes json["updated"], "scanning.ao3_frequency"

        assert_equal 24, settings(:ao3_frequency).reload.value
      end

      test "update handles bulk updates" do
        patch api_v1_settings_url, headers: @headers, params: {
          settings: {
            "scanning.ao3_frequency" => 24,
            "scoring.momentum_weight" => 7
          }
        }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 2, json["updated"].length
      end

      test "update rejects invalid values" do
        patch api_v1_settings_url, headers: @headers, params: {
          settings: { "scanning.ao3_frequency" => -1 }
        }, as: :json
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json["errors"].key?("scanning.ao3_frequency")
      end

      test "update rejects unknown keys" do
        patch api_v1_settings_url, headers: @headers, params: {
          settings: { "nonexistent.key" => 42 }
        }, as: :json
        assert_response :unprocessable_entity

        json = JSON.parse(response.body)
        assert json["errors"].key?("nonexistent.key")
      end

      test "update rolls back all changes on any failure" do
        original_value = settings(:ao3_frequency).value

        patch api_v1_settings_url, headers: @headers, params: {
          settings: {
            "scanning.ao3_frequency" => 24,
            "scanning.reddit_frequency" => -1
          }
        }, as: :json
        assert_response :unprocessable_entity

        assert_equal original_value, settings(:ao3_frequency).reload.value
      end

      # GET /settings/api_keys

      test "api_keys returns api key status" do
        get api_v1_settings_api_keys_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
        assert json.length > 0

        json.each do |entry|
          assert entry["key"].start_with?("api_keys.")
          assert [true, false].include?(entry["configured"])
          assert_not_nil entry["description"]
        end
      end

      # POST /settings/test_connection

      test "test_connection returns placeholder response" do
        post api_v1_settings_test_connection_url, headers: @headers, params: { service: "etsy" }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "Connection test queued", json["message"]
        assert_equal "etsy", json["service"]
      end

      test "test_connection defaults service to unknown" do
        post api_v1_settings_test_connection_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "unknown", json["service"]
      end
    end
  end
end
