module Api
  module V1
    # API controller for managing Design resources.
    # Provides CRUD operations plus endpoints for design regeneration and review workflow.
    class DesignsController < BaseController
      before_action :set_design, only: [:show, :update, :destroy, :regenerate]

      # Lists all designs with optional filtering and sorting.
      #
      # @param [String] status Optional filter by design status (e.g., 'pending_review', 'approved')
      # @param [String] design_type Optional filter by design type
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated designs with metadata
      # @example GET /api/v1/designs?status=approved&sort=created_at DESC
      def index
        designs = Design.all

        # Filter by status
        designs = designs.where(status: params[:status]) if params[:status].present?

        # Filter by design type
        designs = designs.where(design_type: params[:design_type]) if params[:design_type].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id design_type status style generation_cost created_at updated_at],
          default: 'created_at DESC'
        )
        return unless sort_order # Early return if validation failed

        designs = designs.order(sort_order)

        render_paginated(designs)
      end

      # Shows details of a specific design.
      #
      # @return [JSON] Design record
      # @example GET /api/v1/designs/123
      def show
        render json: serialize_design(@design)
      end

      # Creates a new design.
      #
      # @param [Hash] design Design attributes
      # @option design [Integer] :cultural_token_id Foreign key to CulturalToken
      # @option design [String] :prompt_used AI generation prompt
      # @option design [String] :image_url URL to generated design image
      # @option design [String] :design_type Type of design
      # @option design [String] :style Design style
      # @option design [String] :status Review status
      # @option design [Float] :generation_cost Cost to generate in USD
      # @return [JSON] Created design (201) or validation errors (422)
      # @example POST /api/v1/designs
      def create
        design = Design.new(design_params)

        if params[:generate] && design.valid?
          generator = Designs::GeminiGenerator.new
          result = generator.generate(prompt: design.prompt_used || "", style: design.style)
          design.prompt_used ||= result[:content]
          design.generation_cost = result[:estimated_cost]
        end

        if design.save
          render json: serialize_design(design), status: :created
        else
          render json: { errors: design.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing design.
      #
      # @param [Hash] design Design attributes to update (see create for options)
      # @return [JSON] Updated design (200) or validation errors (422)
      # @example PATCH /api/v1/designs/123
      def update
        if @design.update(design_params)
          render json: @design
        else
          render json: { errors: @design.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Hard deletes a design from the database.
      #
      # @return [HTTP 204] No content on success
      # @note Unlike products/niches, this performs a hard delete
      # @example DELETE /api/v1/designs/123
      def destroy
        @design.destroy
        head :no_content
      end

      # Queues regeneration of a design with revised parameters.
      #
      # @return [JSON] Confirmation message
      # @note Not yet implemented - returns placeholder response
      # @example POST /api/v1/designs/123/regenerate
      def regenerate
        # TODO: Trigger design regeneration job
        render json: { message: "Design regeneration queued" }
      end

      private

      # Finds and sets @design from params[:id].
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] if design doesn't exist
      def set_design
        @design = Design.find(params[:id])
      end

      # Strong parameters for design create/update operations.
      # @return [ActionController::Parameters] Permitted design attributes
      def design_params
        params.require(:design).permit(
          :cultural_token_id, :prompt_used, :image_url, :design_type,
          :style, :status, :generation_cost, :image
        )
      end

      def serialize_design(design)
        json = design.as_json
        if design.image.attached?
          json["image_url"] = url_for(design.image)
        end
        json
      end
    end
  end
end
