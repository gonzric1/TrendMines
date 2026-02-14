module Api
  module V1
    class DesignsController < BaseController
      before_action :set_design, only: [:show, :update, :destroy, :regenerate]

      # GET /api/v1/designs
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

      # GET /api/v1/designs/:id
      def show
        render json: @design
      end

      # POST /api/v1/designs
      def create
        design = Design.new(design_params)

        if design.save
          render json: design, status: :created
        else
          render json: { errors: design.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/designs/:id
      def update
        if @design.update(design_params)
          render json: @design
        else
          render json: { errors: @design.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/designs/:id
      def destroy
        @design.destroy
        head :no_content
      end

      # POST /api/v1/designs/:id/regenerate
      def regenerate
        # TODO: Trigger design regeneration job
        render json: { message: "Design regeneration queued" }
      end

      private

      def set_design
        @design = Design.find(params[:id])
      end

      def design_params
        params.require(:design).permit(
          :cultural_token_id, :prompt_used, :image_url, :design_type,
          :style, :status, :generation_cost
        )
      end
    end
  end
end
