require "test_helper"

module Api
  module V1
    class CulturalTokensControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'test-api-key-for-test-suite')
        @headers = { 'X-API-Key' => @api_key }
        @token = cultural_tokens(:frieren_quote)
      end

      test "should require API key" do
        get api_v1_cultural_tokens_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_cultural_tokens_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should filter by niche_id" do
        niche_id = niches(:frieren_collectors).id
        get api_v1_cultural_tokens_url(niche_id: niche_id), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |token|
          assert_equal niche_id, token['niche_id']
        end
      end

      test "should filter by token_type" do
        get api_v1_cultural_tokens_url(token_type: 'quote'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |token|
          assert_equal 'quote', token['token_type']
        end
      end

      test "should filter by status" do
        get api_v1_cultural_tokens_url(status: 'listed'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |token|
          assert_equal 'listed', token['status']
        end
      end

      test "should show cultural token" do
        get api_v1_cultural_token_url(@token), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @token.id, json['id']
      end

      test "should create cultural token" do
        assert_difference('CulturalToken.count') do
          post api_v1_cultural_tokens_url, headers: @headers, params: {
            cultural_token: {
              niche_id: niches(:frieren_collectors).id,
              token_type: 'quote',
              value: 'New Quote',
              status: 'extracted'
            }
          }
        end

        assert_response :created
      end

      test "should not create cultural token with invalid params" do
        assert_no_difference('CulturalToken.count') do
          post api_v1_cultural_tokens_url, headers: @headers, params: {
            cultural_token: { value: nil }
          }
        end

        assert_response :unprocessable_entity
      end

      test "should update cultural token" do
        patch api_v1_cultural_token_url(@token), headers: @headers, params: {
          cultural_token: { value: 'Updated Value' }
        }

        assert_response :success
        @token.reload
        assert_equal 'Updated Value', @token.value
      end

      test "should destroy cultural token" do
        # Create a token with no dependent designs to avoid foreign key issues
        token = CulturalToken.create!(
          niche: niches(:archived_niche),
          token_type: "quote",
          value: "Test Token to Delete",
          status: "extracted"
        )

        assert_difference('CulturalToken.count', -1) do
          delete api_v1_cultural_token_url(token), headers: @headers
        end

        assert_response :no_content
      end

      test "should get token sources" do
        get sources_api_v1_cultural_token_url(@token), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['source_references']
      end

      test "should queue design generation" do
        extracted_token = cultural_tokens(:bg3_character)
        post generate_api_v1_cultural_token_url(extracted_token), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['message'].present?
        assert_equal "queued", json['status']
      end

      test "should reject design generation for non-extracted token" do
        post generate_api_v1_cultural_token_url(@token), headers: @headers
        assert_response :unprocessable_entity
      end
    end
  end
end
