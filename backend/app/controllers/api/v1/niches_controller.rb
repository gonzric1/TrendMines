module Api
  module V1
    class NichesController < BaseController
      before_action :set_niche, only: [:show, :update, :destroy, :tokens, :designs, :scorecard]

      # GET /api/v1/niches
      def index
        niches = Niche.all

        # Filter by status
        niches = niches.where(status: params[:status]) if params[:status].present?

        # Sort
        niches = niches.order(params[:sort] || 'demand_supply_ratio DESC')

        render_paginated(niches)
      end

      # GET /api/v1/niches/:id
      def show
        render json: @niche
      end

      # POST /api/v1/niches
      def create
        niche = Niche.new(niche_params)

        if niche.save
          render json: niche, status: :created
        else
          render json: { errors: niche.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/niches/:id
      def update
        if @niche.update(niche_params)
          render json: @niche
        else
          render json: { errors: @niche.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/niches/:id
      def destroy
        @niche.update(status: :archived)
        head :no_content
      end

      # GET /api/v1/niches/:id/tokens
      def tokens
        render json: @niche.cultural_tokens
      end

      # GET /api/v1/niches/:id/designs
      def designs
        designs = Design.joins(cultural_token: :niche).where(niches: { id: @niche.id })
        render json: designs
      end

      # GET /api/v1/niches/:id/scorecard
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
