module Api
  module V1
    # API controller for managing Niche resources.
    # Provides CRUD operations plus endpoints for cultural tokens, designs, and demand/supply analysis.
    class NichesController < BaseController
      before_action :set_niche, only: [:show, :update, :destroy, :tokens, :designs, :scorecard]

      # Lists all niches with optional filtering and sorting.
      #
      # @param [String] status Optional filter by niche status
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated niches with metadata
      # @example GET /api/v1/niches?status=evaluating&sort=demand_supply_ratio DESC
      def index
        niches = Niche.all

        # Filter by status
        niches = niches.where(status: params[:status]) if params[:status].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id name status demand_score supply_score demand_supply_ratio ao3_works_count ao3_growth_rate etsy_listing_count created_at updated_at discovered_at],
          default: 'demand_supply_ratio DESC'
        )
        return unless sort_order # Early return if validation failed

        niches = niches.order(sort_order)

        render_paginated(niches)
      end

      # Shows details of a specific niche.
      #
      # @return [JSON] Niche record
      # @example GET /api/v1/niches/123
      def show
        render json: @niche
      end

      # Creates a new niche.
      #
      # @param [Hash] niche Niche attributes
      # @option niche [Integer] :trend_signal_id Foreign key to TrendSignal
      # @option niche [String] :name Name of the niche
      # @option niche [String] :description Detailed description
      # @option niche [String] :community_type Type of community
      # @option niche [Float] :demand_score Demand metric
      # @option niche [Float] :supply_score Supply metric
      # @option niche [Float] :demand_supply_ratio Demand/supply ratio
      # @option niche [Integer] :ao3_works_count AO3 works count
      # @option niche [Float] :ao3_growth_rate AO3 growth rate
      # @option niche [Integer] :etsy_listing_count Etsy listing count
      # @option niche [String] :status Pipeline status
      # @option niche [DateTime] :discovered_at Discovery timestamp
      # @return [JSON] Created niche (201) or validation errors (422)
      # @example POST /api/v1/niches
      def create
        niche = Niche.new(niche_params)

        if niche.save
          render json: niche, status: :created
        else
          render json: { errors: niche.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing niche.
      #
      # @param [Hash] niche Niche attributes to update (see create for options)
      # @return [JSON] Updated niche (200) or validation errors (422)
      # @example PATCH /api/v1/niches/123
      def update
        if @niche.update(niche_params)
          render json: @niche
        else
          render json: { errors: @niche.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Soft deletes a niche by setting status to archived.
      #
      # @return [HTTP 204] No content on success
      # @note Does not actually delete the record, sets status to :archived
      # @example DELETE /api/v1/niches/123
      def destroy
        @niche.update(status: :archived)
        head :no_content
      end

      # Lists all cultural tokens extracted from this niche.
      #
      # @return [JSON] Array of CulturalToken records
      # @example GET /api/v1/niches/123/tokens
      def tokens
        render json: @niche.cultural_tokens
      end

      # Lists all designs generated from this niche's cultural tokens.
      #
      # @return [JSON] Array of Design records
      # @example GET /api/v1/niches/123/designs
      def designs
        designs = Design.joins(cultural_token: :niche).where(niches: { id: @niche.id })
        render json: designs
      end

      # Returns a comprehensive demand/supply scorecard for this niche.
      # Includes all metrics used to evaluate commercial potential.
      #
      # @return [JSON] Scorecard with niche details and all demand/supply metrics
      # @example GET /api/v1/niches/123/scorecard
      def scorecard
        render json: {
          niche: @niche,
          demand_score: @niche.demand_score,
          supply_score: @niche.supply_score,
          demand_supply_ratio: @niche.demand_supply_ratio,
          ao3_metrics: {
            works_count: @niche.ao3_works_count,
            growth_rate: @niche.ao3_growth_rate
          },
          etsy_listing_count: @niche.etsy_listing_count
        }
      end

      private

      def set_niche
        @niche = Niche.find(params[:id])
      end

      def niche_params
        params.require(:niche).permit(
          :trend_signal_id, :name, :description, :community_type,
          :demand_score, :supply_score, :demand_supply_ratio,
          :ao3_works_count, :ao3_growth_rate, :etsy_listing_count,
          :status, :discovered_at
        )
      end
    end
  end
end
