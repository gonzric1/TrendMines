require "test_helper"

class Designs::GenerationPipelineTest < ActiveSupport::TestCase
  setup do
    @token = cultural_tokens(:bg3_character)
  end

  test "generates designs for a cultural token" do
    mock_generator = Minitest::Mock.new
    4.times do
      mock_generator.expect(:generate, {
        content: "Generated design content",
        model: "gemini-2.0-flash-exp",
        usage: { "promptTokenCount" => 10 },
        estimated_cost: 0.05
      }, [], prompt: String, style: String)
    end

    Designs::GeminiGenerator.stub(:new, mock_generator) do
      result = Designs::GenerationPipeline.new(cultural_token_id: @token.id).call

      assert_equal 4, result[:designs].length
      assert_equal 0.20, result[:total_cost]
      result[:designs].each do |design|
        assert_equal "pending_review", design.status
        assert_equal @token.id, design.cultural_token_id
        assert design.prompt_used.present?
        assert design.style.present?
      end
    end
  end

  test "transitions token to designs_pending then designs_ready" do
    assert_equal "extracted", @token.status

    mock_generator = Minitest::Mock.new
    4.times do
      mock_generator.expect(:generate, {
        content: "content", model: "gemini-2.0-flash-exp",
        usage: {}, estimated_cost: 0.0
      }, [], prompt: String, style: String)
    end

    Designs::GeminiGenerator.stub(:new, mock_generator) do
      Designs::GenerationPipeline.new(cultural_token_id: @token.id).call
    end

    @token.reload
    assert_equal "designs_ready", @token.status
  end

  test "maps token types to design types" do
    pipeline = Designs::GenerationPipeline.new(cultural_token_id: @token.id)

    assert_equal "art_print", pipeline.send(:design_type_for, "character")
    assert_equal "sticker", pipeline.send(:design_type_for, "quote")
    assert_equal "sticker", pipeline.send(:design_type_for, "phrase")
    assert_equal "graphic", pipeline.send(:design_type_for, "symbol")
    assert_equal "poster", pipeline.send(:design_type_for, "meme")
    assert_equal "graphic", pipeline.send(:design_type_for, "unknown")
  end

  test "respects variant count parameter" do
    mock_generator = Minitest::Mock.new
    2.times do
      mock_generator.expect(:generate, {
        content: "content", model: "gemini-2.0-flash-exp",
        usage: {}, estimated_cost: 0.01
      }, [], prompt: String, style: String)
    end

    Designs::GeminiGenerator.stub(:new, mock_generator) do
      result = Designs::GenerationPipeline.new(
        cultural_token_id: @token.id,
        variant_count: 2
      ).call

      assert_equal 2, result[:designs].length
    end
  end

  test "clamps variant count between 1 and 6" do
    pipeline = Designs::GenerationPipeline.new(
      cultural_token_id: @token.id,
      variant_count: 10
    )
    assert_equal 6, pipeline.instance_variable_get(:@variant_count)

    pipeline = Designs::GenerationPipeline.new(
      cultural_token_id: @token.id,
      variant_count: 0
    )
    assert_equal 1, pipeline.instance_variable_get(:@variant_count)
  end

  test "raises and logs on generator failure" do
    mock_generator = Minitest::Mock.new
    mock_generator.expect(:generate, nil) do
      raise "Gemini API error (500): Internal Server Error"
    end

    Designs::GeminiGenerator.stub(:new, mock_generator) do
      assert_raises(RuntimeError) do
        Designs::GenerationPipeline.new(cultural_token_id: @token.id).call
      end
    end
  end

  test "raises RecordNotFound for invalid token id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Designs::GenerationPipeline.new(cultural_token_id: -1)
    end
  end

  test "builds prompt with template variables" do
    pipeline = Designs::GenerationPipeline.new(cultural_token_id: @token.id)
    prompt = pipeline.send(:build_prompt, "anime_style")

    assert_includes prompt, @token.value
    assert_includes prompt, @token.niche.name
    assert_includes prompt, @token.token_type
    assert_includes prompt, settings(:design_prompt_prefix).value
    assert_includes prompt, settings(:design_prompt_suffix).value
  end

  test "tracks total generation cost" do
    mock_generator = Minitest::Mock.new
    4.times do
      mock_generator.expect(:generate, {
        content: "content", model: "gemini-2.0-flash-exp",
        usage: {}, estimated_cost: 0.10
      }, [], prompt: String, style: String)
    end

    Designs::GeminiGenerator.stub(:new, mock_generator) do
      pipeline = Designs::GenerationPipeline.new(cultural_token_id: @token.id)
      result = pipeline.call

      assert_equal 0.40, result[:total_cost]
      assert_equal 0.40, pipeline.total_cost
    end
  end
end
