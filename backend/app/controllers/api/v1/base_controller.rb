module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_api_key

      private

      def authenticate_api_key
        api_key = request.headers['X-API-Key']

        # Fail hard if API_KEY not set - prevents insecure deployments
        expected_key = ENV.fetch('API_KEY')

        # For now, we'll use a simple env variable check
        # TODO: Move to proper API key management in database
        unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_key)
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      rescue KeyError => e
        # Log error and return 500 if API_KEY is not configured
        Rails.logger.error("API_KEY environment variable not set: #{e.message}")
        render json: { error: 'Server misconfiguration' }, status: :internal_server_error
      end

      def paginate(collection)
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 25, 100].min

        paginated = collection.offset((page - 1) * per_page).limit(per_page)

        {
          data: paginated,
          meta: {
            total: collection.count,
            page: page,
            per_page: per_page,
            total_pages: (collection.count.to_f / per_page).ceil
          }
        }
      end

      def render_paginated(collection)
        result = paginate(collection)
        render json: result
      end

      # Sanitize sort parameters to prevent SQL injection
      # @param allowed_columns [Array<String>] Whitelist of sortable columns
      # @param default [String] Default sort order (e.g., 'created_at DESC')
      # @return [String] Sanitized SQL ORDER BY clause
      def sanitize_sort_params(allowed_columns:, default:)
        return default unless params[:sort].present?

        sort_param = params[:sort].to_s.strip

        # Parse column and direction
        parts = sort_param.split(/\s+/)
        column = parts[0]
        direction = parts[1]&.upcase

        # Validate column against whitelist
        unless allowed_columns.include?(column)
          render json: { error: "Invalid sort column. Allowed: #{allowed_columns.join(', ')}" },
                 status: :bad_request
          return nil
        end

        # Validate direction (only ASC or DESC allowed)
        if direction.present? && !['ASC', 'DESC'].include?(direction)
          render json: { error: "Invalid sort direction. Use ASC or DESC" },
                 status: :bad_request
          return nil
        end

        # Build sanitized sort string
        direction ||= 'ASC'
        "#{column} #{direction}"
      end
    end
  end
end
