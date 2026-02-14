module Api
  module V1
    # API controller for managing CulturalToken resources.
    # Provides CRUD operations plus endpoints for source tracking and design generation.
    class CulturalTokensController < BaseController
      before_action :set_token, only: [:show, :update, :destroy, :sources, :generate]

      # Lists all cultural tokens with optional filtering and sorting.
      #
      # @param [Integer] niche_id Optional filter by parent niche
      # @param [String] token_type Optional filter by token type (e.g., 'phrase', 'symbol')
      # @param [String] status Optional filter by production status
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated cultural tokens with metadata
      # @example GET /api/v1/cultural_tokens?niche_id=5&sort=composite_score DESC
      def index
        tokens = CulturalToken.all

        # Filter by niche
        tokens = tokens.where(niche_id: params[:niche_id]) if params[:niche_id].present?

        # Filter by token type
        tokens = tokens.where(token_type: params[:token_type]) if params[:token_type].present?

        # Filter by status
        tokens = tokens.where(status: params[:status]) if params[:status].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id token_type value status frequency_score emotional_intensity visual_potential uniqueness_score composite_score created_at updated_at],
          default: 'composite_score DESC'
        )
        return unless sort_order # Early return if validation failed

        tokens = tokens.order(sort_order)

        render_paginated(tokens)
      end

      # Shows details of a specific cultural token.
      #
      # @return [JSON] CulturalToken record
      # @example GET /api/v1/cultural_tokens/123
      def show
        render json: @token
      end

      # Creates a new cultural token.
      #
      # @param [Hash] cultural_token Token attributes
      # @option cultural_token [Integer] :niche_id Foreign key to Niche
      # @option cultural_token [String] :token_type Type of token (e.g., 'phrase', 'symbol', 'character', 'meme')
      # @option cultural_token [String] :value The actual token content
      # @option cultural_token [Float] :frequency_score Frequency metric
      # @option cultural_token [Float] :emotional_intensity Emotional impact score
      # @option cultural_token [Float] :visual_potential Design conversion potential
      # @option cultural_token [Float] :uniqueness_score Uniqueness metric
      # @option cultural_token [Float] :composite_score Overall viability score
      # @option cultural_token [String] :status Production status
      # @option cultural_token [Hash] :source_references Original source references
      # @return [JSON] Created token (201) or validation errors (422)
      # @example POST /api/v1/cultural_tokens
      def create
        token = CulturalToken.new(cultural_token_params)

        if token.save
          render json: token, status: :created
        else
          render json: { errors: token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing cultural token.
      #
      # @param [Hash] cultural_token Token attributes to update (see create for options)
      # @return [JSON] Updated token (200) or validation errors (422)
      # @example PATCH /api/v1/cultural_tokens/123
      def update
        if @token.update(cultural_token_params)
          render json: @token
        else
          render json: { errors: @token.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Hard deletes a cultural token from the database.
      #
      # @return [HTTP 204] No content on success
      # @note Performs a hard delete
      # @example DELETE /api/v1/cultural_tokens/123
      def destroy
        @token.destroy
        head :no_content
      end

      # Returns source references for this cultural token.
      #
      # @return [JSON] Hash containing source references
      # @example GET /api/v1/cultural_tokens/123/sources
      def sources
        render json: { source_references: @token.source_references }
      end

      # Queues design generation for this cultural token.
      #
      # @return [JSON] Confirmation message
      # @note Not yet implemented - returns placeholder response
      # @example POST /api/v1/cultural_tokens/123/generate
      def generate
        # TODO: Trigger design generation job
        render json: { message: "Design generation queued for token #{@token.id}" }
      end

      private

      # Finds and sets @token from params[:id].
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] if token doesn't exist
      def set_token
        @token = CulturalToken.find(params[:id])
      end

      # Strong parameters for cultural token create/update operations.
      # @return [ActionController::Parameters] Permitted token attributes
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
