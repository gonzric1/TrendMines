require "test_helper"

module Api
  module V1
    class ProductsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'test-api-key-for-test-suite')
        @headers = { 'X-API-Key' => @api_key }
        @product = products(:frieren_sticker_product)
      end

      test "should require API key" do
        get api_v1_products_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_products_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should filter by product_type" do
        get api_v1_products_url(product_type: 'vinyl_sticker'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |product|
          assert_equal 'vinyl_sticker', product['product_type']
        end
      end

      test "should filter by status" do
        get api_v1_products_url(status: 'listed'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |product|
          assert_equal 'listed', product['status']
        end
      end

      test "should paginate results" do
        get api_v1_products_url(page: 1, per_page: 1), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal 1, json['data'].length
        assert_equal 1, json['meta']['page']
      end

      test "should show product" do
        get api_v1_product_url(@product), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @product.id, json['id']
      end

      test "should create product" do
        assert_difference('Product.count') do
          post api_v1_products_url, headers: @headers, params: {
            product: {
              design_id: designs(:frieren_sticker).id,
              product_type: 'vinyl_sticker',
              name: 'New Product',
              status: 'prototype'
            }
          }
        end

        assert_response :created
      end

      test "should not create product with invalid params" do
        assert_no_difference('Product.count') do
          post api_v1_products_url, headers: @headers, params: {
            product: {
              design_id: designs(:frieren_sticker).id,
              name: nil
            }
          }
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)
        assert json['errors'].present?
      end

      test "should update product" do
        patch api_v1_product_url(@product), headers: @headers, params: {
          product: { name: 'Updated Name' }
        }

        assert_response :success
        @product.reload
        assert_equal 'Updated Name', @product.name
      end

      test "should not update product with invalid params" do
        patch api_v1_product_url(@product), headers: @headers, params: {
          product: { name: nil }
        }

        assert_response :unprocessable_entity
      end

      test "should retire product on destroy" do
        delete api_v1_product_url(@product), headers: @headers
        assert_response :no_content

        @product.reload
        assert_equal 'retired', @product.status
      end

      test "should get product listings" do
        get listings_api_v1_product_url(@product), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
      end

      test "should get product metrics" do
        get metrics_api_v1_product_url(@product), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
      end

      test "should queue listing creation" do
        post list_api_v1_product_url(@product), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['message'].present?
      end

      # SQL Injection Protection Tests
      test "should allow valid sort column with ASC" do
        get api_v1_products_url(sort: 'name ASC'), headers: @headers
        assert_response :success
      end

      test "should allow valid sort column with DESC" do
        get api_v1_products_url(sort: 'created_at DESC'), headers: @headers
        assert_response :success
      end

      test "should allow valid sort column without direction" do
        get api_v1_products_url(sort: 'name'), headers: @headers
        assert_response :success
      end

      test "should reject invalid sort column" do
        get api_v1_products_url(sort: 'invalid_column'), headers: @headers
        assert_response :bad_request

        json = JSON.parse(response.body)
        assert_includes json['error'], 'Invalid sort column'
      end

      test "should reject SQL injection in sort column" do
        get api_v1_products_url(sort: 'id);DROP TABLE products;--'), headers: @headers
        assert_response :bad_request

        json = JSON.parse(response.body)
        assert_includes json['error'], 'Invalid sort column'
      end

      test "should reject invalid sort direction" do
        get api_v1_products_url(sort: 'name INVALID'), headers: @headers
        assert_response :bad_request

        json = JSON.parse(response.body)
        assert_includes json['error'], 'Invalid sort direction'
      end

      test "should reject SQL injection in sort direction" do
        get api_v1_products_url(sort: 'name; DROP TABLE products;'), headers: @headers
        assert_response :bad_request

        json = JSON.parse(response.body)
        # The semicolon makes it parse as column 'name;' which is rejected
        assert_includes json['error'], 'Invalid sort column'
      end

      test "should reject UNION injection attempt" do
        get api_v1_products_url(sort: 'name UNION SELECT * FROM users--'), headers: @headers
        assert_response :bad_request
      end

      test "should use default sort when sort param is empty" do
        get api_v1_products_url(sort: ''), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
      end
    end
  end
end
