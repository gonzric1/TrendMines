module Api
  module V1
    class TrendSignalsController < BaseController
      before_action :set_trend_signal, only: [:show, :update, :destroy]

      # GET /api/v1/trend_signals
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

      # GET /api/v1/trend_signals/:id
      def show
        render json: @trend_signal
      end

      # POST /api/v1/trend_signals
      def create
        signal = TrendSignal.new(trend_signal_params)

        if signal.save
          render json: signal, status: :created
        else
          render json: { errors: signal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/trend_signals/:id
      def update
        if @trend_signal.update(trend_signal_params)
          render json: @trend_signal
        else
          render json: { errors: @trend_signal.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/trend_signals/:id
      def destroy
        @trend_signal.update(status: :archived)
        head :no_content
      end

      # GET /api/v1/trend_signals/:id/history
      def history
        signal = TrendSignal.find(params[:id])
        # TODO: Implement momentum history tracking
        render json: { message: "History endpoint - to be implemented" }
      end

      private

      def set_trend_signal
        @trend_signal = TrendSignal.find(params[:id])
      end

      def trend_signal_params
        params.require(:trend_signal).permit(
          :source, :topic, :description, :momentum_score,
          :status, :first_seen, :last_updated, raw_data: {}
        )
      end
    end
  end
end
