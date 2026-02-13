module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [:show, :update, :destroy, :listings, :metrics, :list]

      # GET /api/v1/products
      def index
        products = Product.all

        # Filter by product type
        products = products.where(product_type: params[:product_type]) if params[:product_type].present?

        # Filter by status
        products = products.where(status: params[:status]) if params[:status].present?

        # Sort
        products = products.order(params[:sort] || 'created_at DESC')

        render_paginated(products)
      end

      # GET /api/v1/products/:id
      def show
        render json: @product
      end

      # POST /api/v1/products
      def create
        product = Product.new(product_params)

        if product.save
          render json: product, status: :created
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/products/:id
      def update
        if @product.update(product_params)
          render json: @product
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        @product.update(status: :retired)
        head :no_content
      end

      # GET /api/v1/products/:id/listings
      def listings
        render json: @product.listings
      end

      # GET /api/v1/products/:id/metrics
      def metrics
        snapshots = MetricSnapshot.joins(:listing).where(listings: { product_id: @product.id })
        render json: snapshots.order(captured_at: :desc)
      end

      # POST /api/v1/products/:id/list
      def list
        # TODO: Create Etsy listing for this product
        render json: { message: "Etsy listing creation queued" }
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(
          :design_id, :product_type, :name, :unit_cost, :target_price,
          :margin_pct, :print_time_minutes, :units_per_batch,
          :stl_file_url, :status
        )
      end
    end
  end
end
