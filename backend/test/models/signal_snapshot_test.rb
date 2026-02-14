require "test_helper"

class SignalSnapshotTest < ActiveSupport::TestCase
  test "should create valid signal snapshot" do
    snapshot = SignalSnapshot.new(
      trend_signal: trend_signals(:trending_anime),
      captured_at: Time.current
    )
    assert snapshot.valid?
  end

  test "should require captured_at" do
    snapshot = SignalSnapshot.new(
      trend_signal: trend_signals(:trending_anime)
    )
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:captured_at], "can't be blank"
  end

  test "should belong to trend_signal" do
    snapshot = signal_snapshots(:anime_snapshot_1d)
    assert_respond_to snapshot, :trend_signal
    assert_kind_of TrendSignal, snapshot.trend_signal
  end

  test "recent scope should order by captured_at descending" do
    snapshots = SignalSnapshot.recent.to_a
    timestamps = snapshots.map(&:captured_at)
    assert_equal timestamps, timestamps.sort.reverse
  end

  test "for_period scope should return snapshots in date range" do
    start_date = 8.days.ago
    end_date = 2.days.ago

    snapshots = SignalSnapshot.for_period(start_date, end_date)

    snapshots.each do |snapshot|
      assert snapshot.captured_at >= start_date
      assert snapshot.captured_at <= end_date
    end
  end

  test "should store json source_metrics" do
    snapshot = SignalSnapshot.create!(
      trend_signal: trend_signals(:trending_anime),
      captured_at: Time.current,
      momentum_score: 85.0,
      source_metrics: { "twitter_mentions" => 15000, "hashtag_velocity" => 110 }
    )

    snapshot.reload
    assert_equal 15000, snapshot.source_metrics["twitter_mentions"]
    assert_equal 110, snapshot.source_metrics["hashtag_velocity"]
  end
end
