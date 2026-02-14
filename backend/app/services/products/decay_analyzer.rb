module Products
  class DecayAnalyzer
    def initialize(product)
      @product = product
    end

    def call
      snapshots = collect_snapshots

      return no_data_result if snapshots.empty?

      sales_trend = calculate_trend(snapshots, :sales)
      views_trend = calculate_trend(snapshots, :views)
      favorites_trend = calculate_trend(snapshots, :favorites)

      decay_score = calculate_decay_score(sales_trend, views_trend, favorites_trend)

      {
        product_id: @product.id,
        product_name: @product.name,
        status: @product.status,
        decay_score: decay_score.round(2),
        trends: {
          sales: { direction: trend_direction(sales_trend), change_pct: sales_trend.round(1) },
          views: { direction: trend_direction(views_trend), change_pct: views_trend.round(1) },
          favorites: { direction: trend_direction(favorites_trend), change_pct: favorites_trend.round(1) }
        },
        recommendation: recommend_action(decay_score),
        thresholds: load_thresholds,
        snapshot_count: snapshots.size,
        period: "30d"
      }
    end

    private

    def collect_snapshots
      @product.listings.flat_map do |listing|
        listing.metric_snapshots
          .for_period(30.days.ago, Time.current)
          .order(:captured_at)
          .to_a
      end.sort_by(&:captured_at)
    end

    def calculate_trend(snapshots, metric)
      return 0.0 if snapshots.size < 2

      mid = snapshots.size / 2
      first_half = snapshots[0...mid]
      second_half = snapshots[mid..]

      avg_first = first_half.sum { |s| s.send(metric).to_f } / first_half.size
      avg_second = second_half.sum { |s| s.send(metric).to_f } / second_half.size

      return 0.0 if avg_first == 0
      ((avg_second - avg_first) / avg_first * 100)
    end

    def calculate_decay_score(sales_trend, views_trend, favorites_trend)
      # Weighted: sales 50%, views 30%, favorites 20%
      # Negative trends increase decay score
      raw = ((-sales_trend * 0.5) + (-views_trend * 0.3) + (-favorites_trend * 0.2))
      raw.clamp(0.0, 100.0)
    end

    def trend_direction(pct)
      if pct > 5 then "increasing"
      elsif pct < -5 then "declining"
      else "stable"
      end
    end

    def recommend_action(decay_score)
      thresholds = load_thresholds
      if decay_score >= 70
        "retire"
      elsif decay_score >= (thresholds[:sales_decline_threshold] || 0.3) * 100
        "monitor_closely"
      else
        "maintain"
      end
    end

    def load_thresholds
      {
        sales_decline_threshold: Setting.find_by(key: "alerts.sales_drop_threshold")&.value || 0.3,
        view_decline_ratio: Setting.find_by(key: "alerts.view_decline_ratio")&.value || 0.25
      }
    end

    def no_data_result
      {
        product_id: @product.id,
        product_name: @product.name,
        status: @product.status,
        decay_score: 0.0,
        trends: {},
        recommendation: "insufficient_data",
        thresholds: load_thresholds,
        snapshot_count: 0,
        period: "30d"
      }
    end
  end
end
