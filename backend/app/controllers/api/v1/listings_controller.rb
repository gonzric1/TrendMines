module Api
  module V1
    class ListingsController < BaseController
      before_action :set_listing, only: [:show, :update, :destroy]

      # GET /api/v1/listings
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

      # GET /api/v1/listings/:id
      def show
        render json: @listing
      end

      # POST /api/v1/listings
      def create
        listing = Listing.new(listing_params)

        if listing.save
          render json: listing, status: :created
        else
          render json: { errors: listing.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/listings/:id
      def update
        if @listing.update(listing_params)
          render json: @listing
        else
          render json: { errors: @listing.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/listings/:id
      def destroy
        @listing.update(status: :paused)
        head :no_content
      end

      # GET /api/v1/listings/:id/metrics
      def metrics
        listing = Listing.find(params[:id])
        render json: listing.metric_snapshots.order(captured_at: :desc)
      end

      # POST /api/v1/listings/:id/metrics
      def create_metric
        listing = Listing.find(params[:id])
        snapshot = listing.metric_snapshots.build(metric_snapshot_params)

        if snapshot.save
          render json: snapshot, status: :created
        else
          render json: { errors: snapshot.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/listings/alerts
      def alerts
        # TODO: Implement alerts logic
        render json: { message: "Alerts endpoint - to be implemented" }
      end

      # GET /api/v1/listings/leaderboard
      def leaderboard
        # TODO: Implement leaderboard logic
        render json: { message: "Leaderboard endpoint - to be implemented" }
      end

      private

      def set_listing
        @listing = Listing.find(params[:id])
      end

      def listing_params
        params.require(:listing).permit(
          :product_id, :etsy_listing_id, :title, :status, :price, :listed_at
        )
      end

      def metric_snapshot_params
        params.require(:metric_snapshot).permit(
          :views, :favorites, :sales, :fav_view_ratio, :revenue, :captured_at
        )
      end
    end
  end
end
