require "test_helper"

class Designs::GeminiGeneratorTest < ActiveSupport::TestCase
  test "raises error when no API key is configured" do
    generator = Designs::GeminiGenerator.new

    error = assert_raises(RuntimeError) do
      generator.generate(prompt: "Draw a cat")
    end

    assert_equal "Gemini API key not configured", error.message
  end

  test "build_prompt uses TemplateComposer" do
    generator = Designs::GeminiGenerator.new
    composed = generator.send(:build_prompt, "Draw a cat", "watercolor")

    assert_includes composed, "Draw a cat"
    assert_includes composed, settings(:design_prompt_prefix).value
    assert_includes composed, settings(:design_prompt_suffix).value
  end

  test "parse_response extracts content from valid response" do
    generator = Designs::GeminiGenerator.new
    response = {
      "candidates" => [
        {
          "content" => {
            "parts" => [{ "text" => "A beautiful design of a cat" }]
          }
        }
      ],
      "usageMetadata" => { "promptTokenCount" => 10, "candidatesTokenCount" => 20 }
    }

    result = generator.send(:parse_response, response)

    assert_equal "A beautiful design of a cat", result[:content]
    assert_equal "gemini-2.0-flash-exp", result[:model]
    assert_equal 0.0, result[:estimated_cost]
    assert_not_nil result[:usage]
  end

  test "parse_response raises on empty candidates" do
    generator = Designs::GeminiGenerator.new

    error = assert_raises(RuntimeError) do
      generator.send(:parse_response, { "candidates" => [] })
    end

    assert_equal "No candidates in Gemini response", error.message
  end

  test "parse_response raises on nil candidates" do
    generator = Designs::GeminiGenerator.new

    error = assert_raises(RuntimeError) do
      generator.send(:parse_response, {})
    end

    assert_equal "No candidates in Gemini response", error.message
  end
end
