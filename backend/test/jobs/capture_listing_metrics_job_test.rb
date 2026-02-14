require "test_helper"

class CaptureListingMetricsJobTest < ActiveSupport::TestCase
  test "creates metric snapshots for active listings" do
    active_count = Listing.active.count
    assert active_count > 0

    assert_difference "MetricSnapshot.count", active_count do
      CaptureListingMetricsJob.perform_now
    end
  end

  test "skips listings that already have snapshots today" do
    # Run once
    CaptureListingMetricsJob.perform_now
    count_after_first = MetricSnapshot.count

    # Run again — should not create duplicates
    CaptureListingMetricsJob.perform_now
    assert_equal count_after_first, MetricSnapshot.count
  end

  test "skips inactive listings" do
    # Only active listings should get snapshots
    draft_listing = listings(:draft_listing)

    CaptureListingMetricsJob.perform_now

    assert_equal 0, draft_listing.metric_snapshots.where(
      captured_at: Time.current.beginning_of_day..Time.current.end_of_day
    ).count
  end

  test "creates snapshots with valid data" do
    CaptureListingMetricsJob.perform_now

    snapshot = Listing.active.first.metric_snapshots.recent.first
    assert_not_nil snapshot
    assert snapshot.views >= 0
    assert snapshot.favorites >= 0
    assert snapshot.sales >= 0
    assert_not_nil snapshot.captured_at
  end
end
