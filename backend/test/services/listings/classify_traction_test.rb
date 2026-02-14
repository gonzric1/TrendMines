require "test_helper"

class Listings::ClassifyTractionTest < ActiveSupport::TestCase
  test "classifies listing with early sale as scaling" do
    listing = listings(:active_sticker_listing)
    # active_sticker_listing was listed 15 days ago and has sales in snapshots
    result = Listings::ClassifyTraction.new(listing).call

    assert_equal "scaling", result[:label]
    assert_equal "green", result[:color]
    assert_equal "rocket", result[:icon]
    assert result[:recommended_action].present?
  end

  test "classifies listing with high fav/view ratio but no sales as promising" do
    listing = listings(:active_print_listing)
    # Zero out all sales so it's not scaling
    listing.metric_snapshots.update_all(sales: 0, fav_view_ratio: 0.08)

    result = Listings::ClassifyTraction.new(listing).call

    assert_equal "promising", result[:label]
    assert_equal "blue", result[:color]
    assert_equal "trending-up", result[:icon]
  end

  test "classifies listing with views but low engagement as no_signal" do
    listing = listings(:active_print_listing)
    listing.metric_snapshots.update_all(sales: 0, views: 150, favorites: 2, fav_view_ratio: 0.013)

    result = Listings::ClassifyTraction.new(listing).call

    assert_equal "no_signal", result[:label]
    assert_equal "red", result[:color]
    assert_equal "alert-circle", result[:icon]
  end

  test "classifies newly listed listing as new" do
    listing = listings(:active_print_listing)
    listing.update_column(:listed_at, 3.days.ago)
    listing.metric_snapshots.destroy_all

    result = Listings::ClassifyTraction.new(listing).call

    assert_equal "new", result[:label]
    assert_equal "gray", result[:color]
    assert_equal "clock", result[:icon]
  end

  test "classifies listing without listed_at as new" do
    listing = listings(:draft_listing)

    result = Listings::ClassifyTraction.new(listing).call

    assert_equal "new", result[:label]
  end

  test "batch_classify returns results for all active listings" do
    results = Listings::ClassifyTraction.batch_classify

    active_count = Listing.active.count
    assert_equal active_count, results.length
    results.each do |result|
      assert result[:listing_id].present?
      assert result[:label].present?
      assert result[:color].present?
      assert result[:icon].present?
      assert result[:recommended_action].present?
    end
  end

  test "uses default thresholds when settings not configured" do
    # No traction-specific settings exist in fixtures, so defaults should be used
    listing = listings(:active_sticker_listing)
    result = Listings::ClassifyTraction.new(listing).call

    assert_includes %w[scaling promising no_signal new], result[:label]
  end

  test "returns hash with required keys" do
    listing = listings(:active_sticker_listing)
    result = Listings::ClassifyTraction.new(listing).call

    assert result.key?(:label)
    assert result.key?(:icon)
    assert result.key?(:color)
    assert result.key?(:recommended_action)
  end
end
