module Api
  module V1
    # API controller for managing TrendSignal resources.
    # Provides CRUD operations for tracking and monitoring emerging trends from various sources.
    class TrendSignalsController < BaseController
      before_action :set_trend_signal, only: [:show, :update, :destroy]

      # Lists all trend signals with optional filtering and sorting.
      #
      # @param [String] source Optional filter by signal source (e.g., 'twitter', 'reddit')
      # @param [String] status Optional filter by signal status
      # @param [String] sort Sort parameter (column and optional direction)
      # @param [Integer] page Page number (default: 1)
      # @param [Integer] per_page Items per page (default: 25, max: 100)
      # @return [JSON] Paginated trend signals with metadata
      # @example GET /api/v1/trend_signals?source=twitter&sort=momentum_score DESC
      def index
        signals = TrendSignal.all

        # Filter by source
        signals = signals.where(source: params[:source]) if params[:source].present?

        # Filter by status
        signals = signals.where(status: params[:status]) if params[:status].present?

        # Sort with SQL injection protection
        sort_order = sanitize_sort_params(
          allowed_columns: %w[id source topic status momentum_score first_seen last_updated created_at updated_at],
          default: 'momentum_score DESC'
        )
        return unless sort_order # Early return if validation failed

        signals = signals.order(sort_order)

        render_paginated(signals)
      end

      # Shows details of a specific trend signal.
      #
      # @return [JSON] TrendSignal record
      # @example GET /api/v1/trend_signals/123
      def show
        render json: @trend_signal
      end

      # Creates a new trend signal.
      #
      # @param [Hash] trend_signal Signal attributes
      # @option trend_signal [String] :source Source platform (e.g., 'twitter', 'reddit')
      # @option trend_signal [String] :topic Trending topic or keyword
      # @option trend_signal [String] :description Additional context
      # @option trend_signal [Float] :momentum_score Calculated momentum metric
      # @option trend_signal [String] :status Monitoring status
      # @option trend_signal [DateTime] :first_seen When first detected
      # @option trend_signal [DateTime] :last_updated Last update timestamp
      # @option trend_signal [Hash] :raw_data Original data from source
      # @return [JSON] Created signal (201) or validation errors (422)
      # @example POST /api/v1/trend_signals
      def create
        signal = TrendSignal.new(trend_signal_params)

        if signal.save
          render json: signal, status: :created
        else
          render json: { errors: signal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Updates an existing trend signal.
      #
      # @param [Hash] trend_signal Signal attributes to update (see create for options)
      # @return [JSON] Updated signal (200) or validation errors (422)
      # @example PATCH /api/v1/trend_signals/123
      def update
        if @trend_signal.update(trend_signal_params)
          render json: @trend_signal
        else
          render json: { errors: @trend_signal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # Soft deletes a trend signal by setting status to archived.
      #
      # @return [HTTP 204] No content on success
      # @note Does not actually delete the record, sets status to :archived
      # @example DELETE /api/v1/trend_signals/123
      def destroy
        @trend_signal.update(status: :archived)
        head :no_content
      end

      # Returns historical momentum data for a signal.
      #
      # @return [JSON] Momentum history data
      # @note Not yet implemented - returns placeholder response
      # @example GET /api/v1/trend_signals/123/history
      def history
        signal = TrendSignal.find(params[:id])
        # TODO: Implement momentum history tracking
        render json: { message: "History endpoint - to be implemented" }
      end

      private

      # Finds and sets @trend_signal from params[:id].
      # @return [void]
      # @raise [ActiveRecord::RecordNotFound] if signal doesn't exist
      def set_trend_signal
        @trend_signal = TrendSignal.find(params[:id])
      end

      # Strong parameters for trend signal create/update operations.
      # @return [ActionController::Parameters] Permitted signal attributes
      def trend_signal_params
        params.require(:trend_signal).permit(
          :source, :topic, :description, :momentum_score,
          :status, :first_seen, :last_updated, raw_data: {}
        )
      end
    end
  end
end
