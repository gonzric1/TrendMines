module Api
  module V1
    class CulturalTokensController < BaseController
      before_action :set_token, only: [:show, :update, :destroy, :sources, :generate]

      # GET /api/v1/cultural_tokens
      def index
        tokens = CulturalToken.all

        # Filter by niche
        tokens = tokens.where(niche_id: params[:niche_id]) if params[:niche_id].present?

        # Filter by token type
        tokens = tokens.where(token_type: params[:token_type]) if params[:token_type].present?

        # Filter by status
        tokens = tokens.where(status: params[:status]) if params[:status].present?

        # Sort
        tokens = tokens.order(params[:sort] || 'composite_score DESC')

        render_paginated(tokens)
      end

      # GET /api/v1/cultural_tokens/:id
      def show
        render json: @token
      end

      # POST /api/v1/cultural_tokens
      def create
        token = CulturalToken.new(cultural_token_params)

        if token.save
          render json: token, status: :created
        else
          render json: { errors: token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/cultural_tokens/:id
      def update
        if @token.update(cultural_token_params)
          render json: @token
        else
          render json: { errors: @token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/cultural_tokens/:id
      def destroy
        @token.destroy
        head :no_content
      end

      # GET /api/v1/cultural_tokens/:id/sources
      def sources
        render json: { source_references: @token.source_references }
      end

      # POST /api/v1/cultural_tokens/:id/generate
      def generate
        # TODO: Trigger design generation job
        render json: { message: "Design generation queued for token #{@token.id}" }
      end

      private

      def set_token
        @token = CulturalToken.find(params[:id])
      end

      def cultural_token_params
        params.require(:cultural_token).permit(
          :niche_id, :token_type, :value, :frequency_score,
          :emotional_intensity, :visual_potential, :uniqueness_score,
          :composite_score, :status, source_references: {}
        )
      end
    end
  end
end
