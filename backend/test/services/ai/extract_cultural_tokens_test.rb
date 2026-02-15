require "test_helper"

class Ai::ExtractCulturalTokensTest < ActiveSupport::TestCase
  setup do
    @niche = niches(:frieren_collectors)
  end

  test "extracts tokens from AI response" do
    ai_response = [
      {
        "value" => "To the world",
        "token_type" => "quote",
        "emotional_intensity" => 85,
        "frequency_score" => 90,
        "uniqueness_score" => 80,
        "visual_potential" => 75,
        "context" => "Famous quote"
      }
    ].to_json

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| ai_response }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)

      assert_equal 1, tokens.length
      token = tokens.first
      assert_equal "To the world", token.value
      assert_equal "quote", token.token_type
      assert_equal 85.0, token.emotional_intensity
      assert_equal 90.0, token.frequency_score
      assert_equal "extracted", token.status
    end
  end

  test "handles markdown code fences in response" do
    ai_response = "```json\n[{\"value\": \"Test Token\", \"token_type\": \"phrase\", \"emotional_intensity\": 70, \"frequency_score\": 60, \"uniqueness_score\": 65, \"visual_potential\": 80, \"context\": \"test\"}]\n```"

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| ai_response }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)
      assert_equal 1, tokens.length
      assert_equal "Test Token", tokens.first.value
    end
  end

  test "clamps scores to 0-100 range" do
    ai_response = [
      {
        "value" => "Extreme Token",
        "token_type" => "phrase",
        "emotional_intensity" => 150,
        "frequency_score" => -10,
        "uniqueness_score" => 50,
        "visual_potential" => 200,
        "context" => "test"
      }
    ].to_json

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| ai_response }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)
      token = tokens.first
      assert_equal 100.0, token.emotional_intensity
      assert_equal 0.0, token.frequency_score
      assert_equal 100.0, token.visual_potential
    end
  end

  test "falls back to phrase for invalid token_type" do
    ai_response = [
      {
        "value" => "Unknown Type",
        "token_type" => "invalid_type",
        "emotional_intensity" => 50,
        "frequency_score" => 50,
        "uniqueness_score" => 50,
        "visual_potential" => 50,
        "context" => "test"
      }
    ].to_json

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| ai_response }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)
      assert_equal "phrase", tokens.first.token_type
    end
  end

  test "returns empty array when AI is not configured" do
    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { false }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)
      assert_empty tokens
    end
  end

  test "returns empty array on JSON parse error" do
    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| "not valid json at all" }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      tokens = Ai::ExtractCulturalTokens.call(@niche)
      assert_empty tokens
    end
  end
end
