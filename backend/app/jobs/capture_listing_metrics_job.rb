class CaptureListingMetricsJob < ApplicationJob
  queue_as :default

  def perform
    Listing.active.find_each do |listing|
      capture_metrics_for(listing)
    end
  end

  private

  def capture_metrics_for(listing)
    # Idempotency: skip if we already captured today
    return if listing.metric_snapshots.where(
      captured_at: Time.current.beginning_of_day..Time.current.end_of_day
    ).exists?

    # Placeholder metrics (will be replaced with actual Etsy API calls later)
    latest = listing.metric_snapshots.recent.first

    listing.metric_snapshots.create!(
      views: generate_metric(latest&.views || 0, 10, 50),
      favorites: generate_metric(latest&.favorites || 0, 1, 10),
      sales: generate_metric(latest&.sales || 0, 0, 3),
      revenue: listing.price.to_f * generate_metric(latest&.sales || 0, 0, 3),
      captured_at: Time.current
    )
  end

  # Generate realistic-looking placeholder metrics
  # Adds a random delta to the previous value
  def generate_metric(previous, min_delta, max_delta)
    delta = rand(min_delta..max_delta)
    [previous + delta, 0].max
  end
end
