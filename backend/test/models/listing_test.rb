require "test_helper"

class ListingTest < ActiveSupport::TestCase
  test "should create valid listing" do
    listing = Listing.new(
      product: products(:frieren_sticker_product),
      title: "Test Listing",
      status: "draft"
    )
    assert listing.valid?
  end

  test "should require title" do
    listing = Listing.new(
      product: products(:frieren_sticker_product),
      status: "draft"
    )
    assert_not listing.valid?
    assert_includes listing.errors[:title], "can't be blank"
  end

  test "should require status" do
    listing = Listing.new(
      product: products(:frieren_sticker_product),
      title: "Test",
      status: ""
    )
    assert_not listing.valid?
    assert_includes listing.errors[:status], "can't be blank"
  end

  test "should belong to product" do
    listing = listings(:active_sticker_listing)
    assert_respond_to listing, :product
    assert_kind_of Product, listing.product
  end

  test "should have many metric snapshots" do
    listing = listings(:active_sticker_listing)
    assert_respond_to listing, :metric_snapshots
    assert_kind_of ActiveRecord::Associations::CollectionProxy, listing.metric_snapshots
  end

  test "should destroy associated metric snapshots when destroyed" do
    listing = listings(:active_sticker_listing)
    snapshot_count = listing.metric_snapshots.count
    assert snapshot_count > 0, "Listing should have snapshots for this test"

    assert_difference "MetricSnapshot.count", -snapshot_count do
      listing.destroy
    end
  end

  test "should have default status of draft" do
    listing = Listing.create!(
      product: products(:frieren_sticker_product),
      title: "Test"
    )
    assert_equal "draft", listing.status
  end

  test "should allow valid status values" do
    listing = listings(:active_sticker_listing)

    %w[draft active sold_out paused].each do |status|
      listing.status = status
      assert listing.valid?, "Status #{status} should be valid"
    end
  end

  test "active scope should only return active status" do
    active_listings = Listing.active
    statuses = active_listings.pluck(:status).uniq
    assert_equal ["active"], statuses
  end

  test "with_metrics scope should only return listings with snapshots" do
    listings_with_metrics = Listing.with_metrics

    listings_with_metrics.each do |listing|
      assert listing.metric_snapshots.exists?, "Listing should have metric snapshots"
    end
  end
end
