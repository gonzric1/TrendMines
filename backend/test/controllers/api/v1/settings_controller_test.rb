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

      test "should require authentication for update_api_keys" do
        patch api_v1_settings_update_api_keys_url, params: { api_keys: {} }
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

      test "index returns api_keys with status fields" do
        get api_v1_settings_url, headers: @headers
        json = JSON.parse(response.body)

        api_keys = json["api_keys"]
        assert_kind_of Array, api_keys
        assert api_keys.length > 0

        api_keys.each do |entry|
          assert entry.key?("configured")
          assert entry.key?("key")
          assert entry.key?("description")
          assert entry.key?("group")
          assert entry.key?("source")
          assert entry.key?("masked_value")
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
          assert_not_nil entry["key"]
          assert [true, false].include?(entry["configured"])
          assert_not_nil entry["description"]
          assert_not_nil entry["group"]
        end
      end

      # PATCH /settings/api_keys

      test "update_api_keys saves encrypted keys" do
        patch api_v1_settings_update_api_keys_url, headers: @headers, params: {
          api_keys: { "reddit_client_id" => "test-client-id-12345" }
        }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_includes json["saved"], "reddit_client_id"

        # Verify the setting was saved encrypted
        setting = Setting.find_by(key: "api_keys.reddit_client_id")
        assert_not_nil setting
        assert_equal "api_keys", setting.category
        assert_not_equal "test-client-id-12345", setting.value # Should be encrypted
        assert_equal "test-client-id-12345", EncryptedSettingValue.decrypt(setting.value)
      ensure
        Setting.where(key: "api_keys.reddit_client_id").destroy_all
      end

      test "update_api_keys ignores blank values" do
        patch api_v1_settings_update_api_keys_url, headers: @headers, params: {
          api_keys: { "reddit_client_id" => "" }
        }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_empty json["saved"]
      end

      test "update_api_keys ignores unknown key names" do
        patch api_v1_settings_update_api_keys_url, headers: @headers, params: {
          api_keys: { "unknown_key" => "some-value" }
        }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_empty json["saved"]
      end

      test "update_api_keys then api_keys shows configured" do
        patch api_v1_settings_update_api_keys_url, headers: @headers, params: {
          api_keys: { "tumblr_consumer_key" => "test-tumblr-key-abc" }
        }, as: :json
        assert_response :success

        get api_v1_settings_api_keys_url, headers: @headers
        json = JSON.parse(response.body)

        tumblr_entry = json.find { |e| e["key"] == "tumblr_consumer_key" }
        assert_not_nil tumblr_entry
        assert tumblr_entry["configured"]
        assert_equal "database", tumblr_entry["source"]
        assert tumblr_entry["masked_value"].start_with?("test")
        assert tumblr_entry["masked_value"].include?("*")
      ensure
        Setting.where(key: "api_keys.tumblr_consumer_key").destroy_all
      end

      # POST /settings/test_connection

      test "test_connection returns result for known service" do
        post api_v1_settings_test_connection_url, headers: @headers, params: { service: "ao3" }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal "ao3", json["service"]
        # AO3/FandomStats doesn't need credentials, so it should attempt connection
        assert json.key?("success")
        assert json.key?("message")
      end

      test "test_connection returns error for unknown service" do
        post api_v1_settings_test_connection_url, headers: @headers, params: { service: "nonexistent" }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_not json["success"]
        assert_includes json["message"], "Unknown service"
      end

      test "test_connection handles tiktok stub" do
        post api_v1_settings_test_connection_url, headers: @headers, params: { service: "tiktok" }, as: :json
        assert_response :success

        json = JSON.parse(response.body)
        assert_not json["success"]
        assert_includes json["message"], "coming soon"
      end
    end
  end
end
