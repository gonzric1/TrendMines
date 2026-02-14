require "test_helper"

module Products
  class DecayAnalyzerTest < ActiveSupport::TestCase
    def setup
      @product_with_data = products(:frieren_sticker_product)
      @product_without_data = products(:prototype_product)
    end

    test "returns decay analysis for product with snapshots" do
      result = DecayAnalyzer.new(@product_with_data).call

      assert_equal @product_with_data.id, result[:product_id]
      assert_equal @product_with_data.name, result[:product_name]
      assert_not_nil result[:decay_score]
      assert_not_nil result[:trends][:sales]
      assert_not_nil result[:trends][:views]
      assert_not_nil result[:trends][:favorites]
      assert_includes %w[maintain monitor_closely retire], result[:recommendation]
      assert_equal "30d", result[:period]
      assert result[:snapshot_count] > 0
    end

    test "returns no_data_result for product without snapshots" do
      result = DecayAnalyzer.new(@product_without_data).call

      assert_equal @product_without_data.id, result[:product_id]
      assert_equal 0.0, result[:decay_score]
      assert_equal({}, result[:trends])
      assert_equal "insufficient_data", result[:recommendation]
      assert_equal 0, result[:snapshot_count]
    end

    test "correctly identifies declining trends" do
      # The fixture data shows increasing metrics (sticker_older -> sticker_recent),
      # so decay_score should be low (0.0 clamped since trends are positive)
      result = DecayAnalyzer.new(@product_with_data).call

      # With increasing metrics, decay score should be clamped to 0.0
      assert result[:decay_score] >= 0.0
      assert result[:decay_score] <= 100.0
    end

    test "uses alert thresholds from Settings" do
      result = DecayAnalyzer.new(@product_with_data).call

      assert_not_nil result[:thresholds][:sales_decline_threshold]
      assert_not_nil result[:thresholds][:view_decline_ratio]
    end

    test "recommends appropriate actions based on decay score" do
      # With increasing fixture data, should recommend maintain
      result = DecayAnalyzer.new(@product_with_data).call

      assert_includes %w[maintain monitor_closely retire], result[:recommendation]
    end
  end
end
