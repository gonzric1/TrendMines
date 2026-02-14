module Listings
  class ClassifyTraction
    LABELS = {
      scaling: {
        label: "scaling",
        icon: "rocket",
        color: "green",
        recommended_action: "Increase inventory and consider price optimization"
      },
      promising: {
        label: "promising",
        icon: "trending-up",
        color: "blue",
        recommended_action: "Monitor closely; consider running a promotion to convert interest to sales"
      },
      no_signal: {
        label: "no_signal",
        icon: "alert-circle",
        color: "red",
        recommended_action: "Review SEO tags, photos, and pricing; consider pausing if no improvement"
      },
      new: {
        label: "new",
        icon: "clock",
        color: "gray",
        recommended_action: "Allow more time for data collection before taking action"
      }
    }.freeze

    DEFAULT_THRESHOLDS = {
      organic_sale_window_days: 14,
      fav_view_ratio_promising: 0.05,
      no_signal_min_views: 100,
      new_listing_days: 7
    }.freeze

    def initialize(listing)
      @listing = listing
    end

    def call
      classify
    end

    def self.batch_classify(listings = Listing.active)
      listings.includes(:metric_snapshots).map do |listing|
        {
          listing_id: listing.id,
          title: listing.title,
          **new(listing).call
        }
      end
    end

    private

    def classify
      thresholds = load_thresholds
      latest = @listing.metric_snapshots.recent.first

      if new_listing?(thresholds)
        LABELS[:new].dup
      elsif scaling?(thresholds, latest)
        LABELS[:scaling].dup
      elsif promising?(thresholds, latest)
        LABELS[:promising].dup
      else
        no_signal_or_new(thresholds, latest)
      end
    end

    def new_listing?(thresholds)
      return true unless @listing.listed_at
      @listing.listed_at > thresholds[:new_listing_days].days.ago
    end

    def scaling?(thresholds, latest)
      return false unless latest&.sales&.positive?
      return false unless @listing.listed_at

      first_sale_snapshot = @listing.metric_snapshots
        .where("sales > 0")
        .order(:captured_at)
        .first

      return false unless first_sale_snapshot

      days_to_sale = (first_sale_snapshot.captured_at.to_date - @listing.listed_at.to_date).to_i
      days_to_sale <= thresholds[:organic_sale_window_days]
    end

    def promising?(thresholds, latest)
      return false unless latest
      return false if latest.sales&.positive?

      (latest.fav_view_ratio || 0) > thresholds[:fav_view_ratio_promising]
    end

    def no_signal_or_new(thresholds, latest)
      if latest && (latest.views || 0) > thresholds[:no_signal_min_views] &&
         (latest.fav_view_ratio || 0) < thresholds[:fav_view_ratio_promising]
        LABELS[:no_signal].dup
      else
        LABELS[:new].dup
      end
    end

    def load_thresholds
      settings = Setting.where("key LIKE ?", "alerts.traction_%").index_by(&:key)
      {
        organic_sale_window_days: settings.dig("alerts.traction_organic_sale_window_days")&.value || DEFAULT_THRESHOLDS[:organic_sale_window_days],
        fav_view_ratio_promising: settings.dig("alerts.traction_fav_view_ratio_promising")&.value || DEFAULT_THRESHOLDS[:fav_view_ratio_promising],
        no_signal_min_views: settings.dig("alerts.traction_no_signal_min_views")&.value || DEFAULT_THRESHOLDS[:no_signal_min_views],
        new_listing_days: settings.dig("alerts.traction_new_listing_days")&.value || DEFAULT_THRESHOLDS[:new_listing_days]
      }
    end
  end
end
