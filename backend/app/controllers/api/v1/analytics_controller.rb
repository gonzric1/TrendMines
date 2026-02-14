module Api
  module V1
    # API controller for analytics and reporting endpoints.
    # Provides aggregated data for revenue, pipeline funnel, signal sources, and costs.
    class AnalyticsController < BaseController
      # Revenue aggregation by period with optional product/product_type filtering.
      #
      # @param [String] period Grouping period: daily, weekly, or monthly (default: daily)
      # @param [Date] start_date Start of date range (default: 30 days ago)
      # @param [Date] end_date End of date range (default: today)
      # @param [Integer] product_id Filter by specific product
      # @param [String] product_type Filter by product type
      # @return [JSON] Revenue data grouped by period with totals
      # @example GET /api/v1/analytics/revenue?period=weekly&start_date=2026-01-01
      def revenue
        start_date = parse_date(params[:start_date], 30.days.ago.to_date)
        end_date = parse_date(params[:end_date], Date.current)
        period = params[:period].presence || "daily"

        unless %w[daily weekly monthly].include?(period)
          render json: { error: "Invalid period. Allowed: daily, weekly, monthly" }, status: :bad_request
          return
        end

        snapshots = MetricSnapshot.where(captured_at: start_date.beginning_of_day..end_date.end_of_day)

        # Filter by product if specified
        if params[:product_id].present?
          snapshots = snapshots.joins(:listing).where(listings: { product_id: params[:product_id] })
        end

        if params[:product_type].present?
          snapshots = snapshots.joins(listing: :product).where(products: { product_type: params[:product_type] })
        end

        grouped = group_by_period(snapshots, period)
        total_revenue = snapshots.sum(:revenue)

        render json: {
          period: period,
          start_date: start_date,
          end_date: end_date,
          total_revenue: total_revenue,
          data: grouped
        }
      end

      # Pipeline funnel showing conversion counts at each stage.
      #
      # @return [JSON] Counts at each pipeline stage
      # @example GET /api/v1/analytics/funnel
      def funnel
        total_signals = TrendSignal.count
        promoted_signals = TrendSignal.where(status: "promoted").count
        niches = Niche.count
        tokens_with_designs = CulturalToken.joins(:designs).distinct.count
        products = Product.count
        active_listings = Listing.where(status: "active").count
        listings_with_sales = MetricSnapshot.where("sales > 0").select(:listing_id).distinct.count

        render json: {
          funnel: [
            { stage: "total_signals", count: total_signals },
            { stage: "promoted_signals", count: promoted_signals },
            { stage: "niches", count: niches },
            { stage: "tokens_with_designs", count: tokens_with_designs },
            { stage: "products", count: products },
            { stage: "active_listings", count: active_listings },
            { stage: "listings_with_sales", count: listings_with_sales }
          ]
        }
      end

      # Signal source analysis showing which sources produce the most revenue.
      #
      # @return [JSON] Source breakdown with signal counts and revenue
      # @example GET /api/v1/analytics/sources
      def sources
        source_data = TrendSignal.group(:source).count

        source_stats = source_data.map do |source, signal_count|
          signal_ids = TrendSignal.where(source: source).pluck(:id)

          source_revenue = MetricSnapshot
            .joins(listing: { product: { design: { cultural_token: { niche: :trend_signal } } } })
            .where(trend_signals: { source: source })
            .sum(:revenue)

          product_count = Product
            .joins(design: { cultural_token: { niche: :trend_signal } })
            .where(trend_signals: { source: source })
            .count

          {
            source: source,
            signal_count: signal_count,
            product_count: product_count,
            total_revenue: source_revenue
          }
        end

        render json: { sources: source_stats.sort_by { |s| -s[:total_revenue].to_f } }
      end

      # Cost aggregation across design generation and product materials.
      #
      # @return [JSON] Cost breakdown by category
      # @example GET /api/v1/analytics/costs
      def costs
        design_costs = Design.sum(:generation_cost) || 0
        material_costs = Product.sum(:unit_cost) || 0

        # Estimate Etsy fees: 6.5% transaction fee + $0.20 listing fee per active listing
        total_revenue = MetricSnapshot.sum(:revenue) || 0
        active_listing_count = Listing.where(status: "active").count
        etsy_transaction_fees = total_revenue * 0.065
        etsy_listing_fees = active_listing_count * 0.20

        render json: {
          costs: {
            design_generation: design_costs.to_f,
            material_costs: material_costs.to_f,
            etsy_transaction_fees: etsy_transaction_fees.to_f.round(2),
            etsy_listing_fees: etsy_listing_fees.to_f.round(2),
            total_estimated: (design_costs.to_f + material_costs.to_f + etsy_transaction_fees.to_f + etsy_listing_fees.to_f).round(2)
          },
          total_revenue: total_revenue.to_f
        }
      end

      private

      # Parses a date string, falling back to a default if invalid or missing.
      #
      # @param [String] date_string The date string to parse
      # @param [Date] default The default date to use
      # @return [Date] Parsed date or default
      def parse_date(date_string, default)
        return default unless date_string.present?

        Date.parse(date_string)
      rescue Date::Error
        default
      end

      # Groups MetricSnapshot revenue by the specified period.
      #
      # @param [ActiveRecord::Relation] snapshots MetricSnapshot query
      # @param [String] period Grouping period (daily, weekly, monthly)
      # @return [Array<Hash>] Grouped revenue data
      def group_by_period(snapshots, period)
        grouped = case period
        when "daily"
          snapshots.group("DATE(captured_at)").sum(:revenue)
        when "weekly"
          snapshots.group("strftime('%Y-%W', captured_at)").sum(:revenue)
        when "monthly"
          snapshots.group("strftime('%Y-%m', captured_at)").sum(:revenue)
        end

        grouped.map { |date, rev| { period: date.to_s, revenue: rev.to_f } }
      end
    end
  end
end
