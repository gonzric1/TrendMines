require "test_helper"

class MetricSnapshotTest < ActiveSupport::TestCase
  test "should create valid metric snapshot" do
    snapshot = MetricSnapshot.new(
      listing: listings(:active_sticker_listing),
      captured_at: Time.current
    )
    assert snapshot.valid?
  end

  test "should require captured_at" do
    snapshot = MetricSnapshot.new(
      listing: listings(:active_sticker_listing)
    )
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:captured_at], "can't be blank"
  end

  test "should belong to listing" do
    snapshot = metric_snapshots(:sticker_recent)
    assert_respond_to snapshot, :listing
    assert_kind_of Listing, snapshot.listing
  end

  test "recent scope should order by captured_at descending" do
    snapshots = MetricSnapshot.recent.to_a
    timestamps = snapshots.map(&:captured_at)
    assert_equal timestamps, timestamps.sort.reverse
  end

  test "for_period scope should return snapshots in date range" do
    start_date = 8.days.ago
    end_date = 2.days.ago

    snapshots = MetricSnapshot.for_period(start_date, end_date)

    snapshots.each do |snapshot|
      assert snapshot.captured_at >= start_date
      assert snapshot.captured_at <= end_date
    end
  end

  test "should accept numeric values for metrics" do
    snapshot = MetricSnapshot.create!(
      listing: listings(:active_sticker_listing),
      captured_at: Time.current,
      views: 100,
      favorites: 10,
      sales: 5,
      revenue: 25.50,
      fav_view_ratio: 0.10
    )

    assert_equal 100, snapshot.views
    assert_equal 10, snapshot.favorites
    assert_equal 5, snapshot.sales
    assert_equal 25.50, snapshot.revenue.to_f
    assert_equal 0.10, snapshot.fav_view_ratio
  end
end
