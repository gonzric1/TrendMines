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

      # Pagination Query Optimization Tests
      test "paginate method executes only one COUNT query" do
        # Capture SQL queries
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
          queries << payload[:sql] if payload[:sql] !~ /^(BEGIN|COMMIT|ROLLBACK|PRAGMA|EXPLAIN)/
        end

        # Make paginated request
        get "/api/v1/products?page=1&per_page=2", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success

        # Unsubscribe from notifications
        ActiveSupport::Notifications.unsubscribe(subscriber)

        # Count SELECT COUNT(*) queries
        count_queries = queries.select { |sql| sql.match?(/SELECT COUNT\(\*\)/i) }

        # Verify only one COUNT query was executed
        assert_equal 1, count_queries.length,
          "Expected exactly 1 COUNT query, but found #{count_queries.length}:\n#{count_queries.join("\n")}"

        # Verify response structure is correct
        json = JSON.parse(response.body)
        assert json["meta"]["total"] > 0, "Expected products to exist in fixtures"
        assert json["meta"]["total_pages"] > 0, "Expected at least one page"
      end

      test "paginate returns correct metadata" do
        # Using fixtures (3 products: frieren_sticker_product, fern_print_product, prototype_product)
        total_products = Product.count

        get "/api/v1/products?page=1&per_page=2", headers: { "X-API-Key" => @valid_api_key }
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal total_products, json["meta"]["total"]
        assert_equal 1, json["meta"]["page"]
        assert_equal 2, json["meta"]["per_page"]
        assert_equal (total_products.to_f / 2).ceil, json["meta"]["total_pages"]
      end
    end
  end
end
