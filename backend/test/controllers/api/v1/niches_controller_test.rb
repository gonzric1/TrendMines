require "test_helper"

module Api
  module V1
    class NichesControllerTest < ActionDispatch::IntegrationTest
      def setup
        @api_key = ENV.fetch('API_KEY', 'dev-api-key-change-in-production')
        @headers = { 'X-API-Key' => @api_key }
        @niche = niches(:frieren_collectors)
      end

      test "should require API key" do
        get api_v1_niches_url
        assert_response :unauthorized
      end

      test "should get index" do
        get api_v1_niches_url, headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['data']
        assert_not_nil json['meta']
      end

      test "should filter by status" do
        get api_v1_niches_url(status: 'active'), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        json['data'].each do |niche|
          assert_equal 'active', niche['status']
        end
      end

      test "should show niche" do
        get api_v1_niche_url(@niche), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_equal @niche.id, json['id']
      end

      test "should create niche" do
        assert_difference('Niche.count') do
          post api_v1_niches_url, headers: @headers, params: {
            niche: {
              trend_signal_id: trend_signals(:trending_anime).id,
              name: 'New Niche',
              status: 'discovered'
            }
          }
        end

        assert_response :created
      end

      test "should not create niche with invalid params" do
        assert_no_difference('Niche.count') do
          post api_v1_niches_url, headers: @headers, params: {
            niche: { name: nil }
          }
        end

        assert_response :unprocessable_entity
      end

      test "should update niche" do
        patch api_v1_niche_url(@niche), headers: @headers, params: {
          niche: { name: 'Updated Niche' }
        }

        assert_response :success
        @niche.reload
        assert_equal 'Updated Niche', @niche.name
      end

      test "should archive niche on destroy" do
        delete api_v1_niche_url(@niche), headers: @headers
        assert_response :no_content

        @niche.reload
        assert_equal 'archived', @niche.status
      end

      test "should get niche tokens" do
        get tokens_api_v1_niche_url(@niche), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
      end

      test "should get niche designs" do
        get designs_api_v1_niche_url(@niche), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_kind_of Array, json
      end

      test "should get niche scorecard" do
        get scorecard_api_v1_niche_url(@niche), headers: @headers
        assert_response :success

        json = JSON.parse(response.body)
        assert_not_nil json['niche']
        assert_not_nil json['demand_score']
        assert_not_nil json['ao3_metrics']
      end
    end
  end
end
