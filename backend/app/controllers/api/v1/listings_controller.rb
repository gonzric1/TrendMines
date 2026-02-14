module Api
  module V1
    # API controller for managing Listing resources.
    # Provides CRUD operations plus endpoints for performance metrics, alerts, and leaderboards.
    class ListingsController < BaseController
      before_action :set_listing, only: [:show, :update, :destroy]

      # Lists all marketplace listings with optional filtering and sorting.
      #
      # @param [String] status Optional filter by listing status (e.g., 'active', 'draft')
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated listings with metadata
      # @example GET /api/v1/listings?status=active&sort=listed_at DESC
      def index
        listings = Listing.all

        # Filter by status
        listings = listings.where(status: params[:status]) if params[:status].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id title status price listed_at created_at updated_at],
          default: 'listed_at DESC'
        )
        return unless sort_order # Early return if validation failed

        listings = listings.order(sort_order)

        render_paginated(listings)
      end

      # Shows details of a specific listing.
      #
      # @return [JSON] Listing record
      # @example GET /api/v1/listings/123
      def show
        render json: @listing
      end

      # Creates a new marketplace listing.
      #
      # @param [Hash] listing Listing attributes
      # @option listing [Integer] :product_id Foreign key to Product
      # @option listing [String] :etsy_listing_id External Etsy listing ID
      # @option listing [String] :title Public listing title
      # @option listing [String] :status Listing status
      # @option listing [Float] :price Listing price in USD
      # @option listing [DateTime] :listed_at When the listing went live
      # @return [JSON] Created listing (201) or validation errors (422)
      # @example POST /api/v1/listings
      def create
        listing = Listing.new(listing_params)

        if listing.save
          render json: listing, status: :created
        else
          render json: { errors: listing.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing listing.
      #
      # @param [Hash] listing Listing attributes to update (see create for options)
      # @return [JSON] Updated listing (200) or validation errors (422)
      # @example PATCH /api/v1/listings/123
      def update
        if @listing.update(listing_params)
          render json: @listing
        else
          render json: { errors: @listing.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Soft deletes a listing by setting status to paused.
      #
      # @return [HTTP 204] No content on success
      # @note Does not delete the record, sets status to :paused
      # @example DELETE /api/v1/listings/123
      def destroy
        @listing.update(status: :paused)
        head :no_content
      end

      # Retrieves all performance metric snapshots for a listing.
      #
      # @return [JSON] Array of MetricSnapshot records ordered by capture time (most recent first)
      # @example GET /api/v1/listings/123/metrics
      def metrics
        listing = Listing.find(params[:id])
        render json: listing.metric_snapshots.order(captured_at: :desc)
      end

      # Creates a new metric snapshot for a listing.
      #
      # @param [Hash] metric_snapshot Snapshot attributes
      # @option metric_snapshot [Integer] :views View count
      # @option metric_snapshot [Integer] :favorites Favorite/heart count
      # @option metric_snapshot [Integer] :sales Sales count
      # @option metric_snapshot [Float] :fav_view_ratio Favorite-to-view ratio
      # @option metric_snapshot [Float] :revenue Revenue in USD
      # @option metric_snapshot [DateTime] :captured_at Snapshot timestamp
      # @return [JSON] Created snapshot (201) or validation errors (422)
      # @example POST /api/v1/listings/123/metrics
      def create_metric
        listing = Listing.find(params[:id])
        snapshot = listing.metric_snapshots.build(metric_snapshot_params)

        if snapshot.save
          render json: snapshot, status: :created
        else
          render json: { errors: snapshot.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Returns performance alerts for listings.
      #
      # @return [JSON] Alerts data
      # @note Not yet implemented - returns placeholder response
      # @example GET /api/v1/listings/alerts
      def alerts
        # TODO: Implement alerts logic
        render json: { message: "Alerts endpoint - to be implemented" }
      end

      # Returns top-performing listings leaderboard.
      #
      # @return [JSON] Leaderboard data
      # @note Not yet implemented - returns placeholder response
      # @example GET /api/v1/listings/leaderboard
      def leaderboard
        # TODO: Implement leaderboard logic
        render json: { message: "Leaderboard endpoint - to be implemented" }
      end

      private

      # Finds and sets @listing from params[:id].
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] if listing doesn't exist
      def set_listing
        @listing = Listing.find(params[:id])
      end

      # Strong parameters for listing create/update operations.
      # @return [ActionController::Parameters] Permitted listing attributes
      def listing_params
        params.require(:listing).permit(
          :product_id, :etsy_listing_id, :title, :status, :price, :listed_at
        )
      end

      # Strong parameters for metric snapshot creation.
      # @return [ActionController::Parameters] Permitted snapshot attributes
      def metric_snapshot_params
        params.require(:metric_snapshot).permit(
          :views, :favorites, :sales, :fav_view_ratio, :revenue, :captured_at
        )
      end
    end
  end
end
