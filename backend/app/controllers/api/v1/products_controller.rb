module Api
  module V1
    # API controller for managing Product resources.
    # Provides CRUD operations plus endpoints for listings, metrics, and marketplace integration.
    class ProductsController < BaseController
      before_action :set_product, only: [:show, :update, :destroy, :listings, :metrics, :list, :decay_analysis, :transition]

      # Lists all products with optional filtering and sorting.
      #
      # @param [String] product_type Optional filter by product type
      # @param [String] status Optional filter by product status
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated products with metadata
      # @example GET /api/v1/products?status=listed&sort=created_at DESC&page=1
      def index
        products = Product.all

        # Filter by product type
        products = products.where(product_type: params[:product_type]) if params[:product_type].present?

        # Filter by status
        products = products.where(status: params[:status]) if params[:status].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id name created_at updated_at product_type status unit_cost target_price margin_pct],
          default: 'created_at DESC'
        )
        return unless sort_order # Early return if validation failed

        products = products.order(sort_order)

        render_paginated(products)
      end

      # Shows details of a specific product.
      #
      # @return [JSON] Product record
      # @example GET /api/v1/products/123
      def show
        render json: @product
      end

      # Creates a new product.
      #
      # @param [Hash] product Product attributes
      # @option product [Integer] :design_id Foreign key to Design
      # @option product [String] :product_type Type of product
      # @option product [String] :name Display name
      # @option product [Float] :unit_cost Cost per unit in USD
      # @option product [Float] :target_price Target selling price in USD
      # @option product [Float] :margin_pct Profit margin percentage
      # @option product [Integer] :print_time_minutes Time to produce one unit
      # @option product [Integer] :units_per_batch Units per batch
      # @option product [String] :stl_file_url URL to STL file
      # @option product [String] :status Lifecycle status
      # @return [JSON] Created product (201) or validation errors (422)
      # @example POST /api/v1/products
      def create
        product = Product.new(product_params)

        if product.save
          render json: product, status: :created
        else
          render json: { errors: product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing product.
      #
      # @param [Hash] product Product attributes to update (see create for options)
      # @return [JSON] Updated product (200) or validation errors (422)
      # @example PATCH /api/v1/products/123
      def update
        if @product.update(product_params)
          render json: @product
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Soft deletes a product by setting status to retired.
      #
      # @return [HTTP 204] No content on success
      # @note Does not actually delete the record, sets status to :retired
      # @example DELETE /api/v1/products/123
      def destroy
        @product.update(status: :retired)
        head :no_content
      end

      # Lists all marketplace listings for this product.
      #
      # @return [JSON] Array of Listing records
      # @example GET /api/v1/products/123/listings
      def listings
        render json: @product.listings
      end

      # Retrieves all performance metric snapshots for this product's listings.
      #
      # @return [JSON] Array of MetricSnapshot records ordered by capture time (most recent first)
      # @example GET /api/v1/products/123/metrics
      def metrics
        snapshots = MetricSnapshot.joins(:listing).where(listings: { product_id: @product.id })
        render json: snapshots.order(captured_at: :desc)
      end

      # Queues creation of an Etsy listing for this product.
      #
      # @return [JSON] Confirmation message
      # @note Not yet implemented - returns placeholder response
      # @example POST /api/v1/products/123/list
      def list
        # TODO: Create Etsy listing for this product
        render json: { message: "Etsy listing creation queued" }
      end

      # Returns decay analysis for a product based on metric trends.
      #
      # @return [JSON] Decay analysis with score, trends, and recommendation
      # @example GET /api/v1/products/123/decay_analysis
      def decay_analysis
        result = Products::DecayAnalyzer.new(@product).call
        render json: result
      end

      # Transitions a product to a new lifecycle status.
      #
      # @param [String] status The target status
      # @return [JSON] Updated product or error
      # @example PATCH /api/v1/products/123/transition
      def transition
        new_status = params[:status]
        allowed = %w[prototype listed scaling declining retired]

        unless allowed.include?(new_status)
          render json: { error: "Invalid status. Allowed: #{allowed.join(', ')}" }, status: :bad_request
          return
        end

        if @product.update(status: new_status)
          render json: @product
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      # Finds and sets @product from params[:id].
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] if product doesn't exist
      def set_product
        @product = Product.find(params[:id])
      end

      # Strong parameters for product create/update operations.
      # @return [ActionController::Parameters] Permitted product attributes
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
