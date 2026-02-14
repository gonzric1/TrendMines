require "test_helper"

class Prompts::TemplateComposerTest < ActiveSupport::TestCase
  test "compose joins prefix, main prompt, and suffix" do
    composer = Prompts::TemplateComposer.new
    result = composer.compose("Draw a cat")

    assert_includes result, settings(:design_prompt_prefix).value
    assert_includes result, "Draw a cat"
    assert_includes result, settings(:design_prompt_suffix).value
  end

  test "compose substitutes variables" do
    composer = Prompts::TemplateComposer.new(niche_name: "Anime", token_value: "Frieren")
    result = composer.compose("Draw {niche_name} character {token_value}")

    assert_includes result, "Draw Anime character Frieren"
    refute_includes result, "{niche_name}"
    refute_includes result, "{token_value}"
  end

  test "compose handles missing templates gracefully" do
    Setting.where(category: "templates").destroy_all
    composer = Prompts::TemplateComposer.new
    result = composer.compose("Draw a cat")

    assert_equal "Draw a cat", result
  end

  test "compose_listing_title substitutes variables" do
    composer = Prompts::TemplateComposer.new(token_value: "Frieren", style: "watercolor")
    result = composer.compose_listing_title(product_type: "T-Shirt")

    assert_includes result, "Frieren"
    assert_includes result, "watercolor"
    assert_includes result, "T-Shirt"
    refute_includes result, "{token_value}"
  end

  test "compose_listing_description substitutes variables" do
    composer = Prompts::TemplateComposer.new(style: "watercolor", token_value: "Frieren", niche_name: "Anime")
    result = composer.compose_listing_description

    assert_includes result, "watercolor"
    assert_includes result, "Frieren"
    assert_includes result, "Anime"
    refute_includes result, "{style}"
  end
end
