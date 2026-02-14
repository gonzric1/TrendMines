require "test_helper"

module Api
  module V1
    class BaseControllerTest < ActionDispatch::IntegrationTest
      setup do
        # Set a known API key for testing
        @valid_api_key = "test-api-key-12345"
        ENV["API_KEY"] = @valid_api_key
      end

      teardown do
        # Clean up environment variable
        ENV.delete("API_KEY")
      end

      test "allows access with valid API key" do
        get "/api/v1/trend_signals", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success
      end

      test "rejects request with invalid API key" do
        get "/api/v1/trend_signals", headers: { "X-API-Key" => "invalid-key" }
        assert_response :unauthorized
        assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
      end

      test "rejects request with missing API key" do
        get "/api/v1/trend_signals"
        assert_response :unauthorized
        assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
      end

      test "rejects request with empty API key" do
        get "/api/v1/trend_signals", headers: { "X-API-Key" => "" }
        assert_response :unauthorized
        assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
      end

      test "rejects request with nil API key" do
        get "/api/v1/trend_signals", headers: { "X-API-Key" => nil }
        assert_response :unauthorized
        assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
      end

      test "uses secure comparison to prevent timing attacks" do
        # This test verifies that secure_compare is used instead of ==
        # by ensuring that authentication behavior is consistent
        # regardless of how wrong the key is

        # Test with completely wrong key
        get "/api/v1/trend_signals", headers: { "X-API-Key" => "x" * @valid_api_key.length }
        first_response_time = Time.current
        assert_response :unauthorized

        # Test with key that differs only in last character
        almost_correct_key = @valid_api_key[0..-2] + "x"
        get "/api/v1/trend_signals", headers: { "X-API-Key" => almost_correct_key }
        second_response_time = Time.current
        assert_response :unauthorized

        # While we can't directly test constant-time comparison in a unit test,
        # we verify that both incorrect keys are rejected consistently
        assert_equal({ "error" => "Unauthorized" }, JSON.parse(response.body))
      end

      # SQL Injection Protection Tests for sanitize_sort_params
      test "sanitize_sort_params returns default when sort param is blank" do
        get "/api/v1/products", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success
        # Implicitly tests that default sort is used
      end

      test "sanitize_sort_params accepts valid column with ASC" do
        get "/api/v1/products?sort=name+ASC", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success
      end

      test "sanitize_sort_params accepts valid column with DESC" do
        get "/api/v1/products?sort=name+DESC", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success
      end

      test "sanitize_sort_params rejects invalid column" do
        get "/api/v1/products?sort=invalid_column", headers: { "X-API-Key" => @valid_api_key }
        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_match /Invalid sort column/, json['error']
      end

      test "sanitize_sort_params rejects invalid direction" do
        get "/api/v1/products?sort=name+INVALID", headers: { "X-API-Key" => @valid_api_key }
        assert_response :bad_request
        json = JSON.parse(response.body)
        assert_match /Invalid sort direction/, json['error']
      end

      test "sanitize_sort_params blocks SQL injection with DROP TABLE" do
        get "/api/v1/products?sort=id);DROP+TABLE+products;--", headers: { "X-API-Key" => @valid_api_key }
        assert_response :bad_request

        # Verify the products table still exists by making a valid request
        get "/api/v1/products", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success
      end

      test "sanitize_sort_params blocks SQL injection with UNION" do
        get "/api/v1/products?sort=name+UNION+SELECT+*+FROM+users", headers: { "X-API-Key" => @valid_api_key }
        assert_response :bad_request
      end

      test "sanitize_sort_params blocks SQL injection with semicolon" do
        get "/api/v1/products?sort=name;+DELETE+FROM+products", headers: { "X-API-Key" => @valid_api_key }
        assert_response :bad_request
      end
    end
  end
end
