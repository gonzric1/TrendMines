require "test_helper"

module Api
  module V1
    class DesignsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'dev-api-key-change-in-production')
        @headers = { 'X-API-Key' => @api_key }
        @design = designs(:frieren_sticker)
      end

      test "should require API key" do
        get api_v1_designs_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_designs_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should filter by status" do
        get api_v1_designs_url(status: 'approved'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |design|
          assert_equal 'approved', design['status']
        end
      end

      test "should filter by design_type" do
        get api_v1_designs_url(design_type: 'sticker'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |design|
          assert_equal 'sticker', design['design_type']
        end
      end

      test "should show design" do
        get api_v1_design_url(@design), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @design.id, json['id']
      end

      test "should create design" do
        assert_difference('Design.count') do
          post api_v1_designs_url, headers: @headers, params: {
            design: {
              cultural_token_id: cultural_tokens(:frieren_quote).id,
              design_type: 'sticker',
              status: 'pending_review'
            }
          }
        end

        assert_response :created
      end

      test "should not create design with invalid params" do
        assert_no_difference('Design.count') do
          post api_v1_designs_url, headers: @headers, params: {
            design: { design_type: nil }
          }
        end

        assert_response :unprocessable_entity
      end

      test "should update design" do
        patch api_v1_design_url(@design), headers: @headers, params: {
          design: { style: 'Updated Style' }
        }

        assert_response :success
        @design.reload
        assert_equal 'Updated Style', @design.style
      end

      test "should destroy design" do
        # Create a design with no products to avoid foreign key issues
        design = Design.create!(
          cultural_token: cultural_tokens(:bg3_character),
          design_type: "sticker",
          status: "rejected"
        )

        assert_difference('Design.count', -1) do
          delete api_v1_design_url(design), headers: @headers
        end

        assert_response :no_content
      end

      test "should queue design regeneration" do
        post regenerate_api_v1_design_url(@design), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert json['message'].present?
      end
    end
  end
end
