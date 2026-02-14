require "test_helper"

class Products::CalculateMarginTest < ActiveSupport::TestCase
  test "calculates correct fees for frieren sticker" do
    product = products(:frieren_sticker_product)
    result = Products::CalculateMargin.new(product).call

    fees = result[:fees]
    assert_equal 0.20, fees[:listing_fee]
    assert_equal (3.99 * 0.065).round(2), fees[:transaction_fee]
    assert_equal (3.99 * 0.03 + 0.25).round(2), fees[:payment_processing_fee]
    assert_equal (0.20 + fees[:transaction_fee] + fees[:payment_processing_fee]).round(2), fees[:total_fees]
  end

  test "calculates correct margin percentage" do
    product = products(:frieren_sticker_product)
    result = Products::CalculateMargin.new(product).call

    assert_equal 3.99, result[:sale_price]
    assert_equal 0.50, result[:unit_cost]
    assert result[:margin_pct] > 0
    assert result[:profit] > 0
    assert result[:total_cost] > result[:unit_cost]
  end

  test "handles zero price" do
    product = products(:frieren_sticker_product)
    product.target_price = 0

    result = Products::CalculateMargin.new(product).call

    assert_equal 0.0, result[:margin_pct]
    assert_equal 0, result[:sale_price]
  end

  test "handles zero cost" do
    product = products(:frieren_sticker_product)
    product.unit_cost = 0

    result = Products::CalculateMargin.new(product).call

    assert_equal 0, result[:unit_cost]
    assert result[:profit] > 0
    assert result[:margin_pct] > 0
  end

  test "calculates break even price" do
    product = products(:frieren_sticker_product)
    result = Products::CalculateMargin.new(product).call

    assert result[:break_even_price] > product.unit_cost
    assert result[:break_even_price] < product.target_price
  end
end
