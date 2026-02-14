module Api
  module V1
    # Base controller for all API v1 endpoints.
    # Provides authentication, pagination, and parameter sanitization
    # shared across all resource controllers.
    class BaseController < ApplicationController
      before_action :authenticate_api_key

      private

      # Authenticates incoming requests using X-API-Key header.
      # Requires API_KEY environment variable to be set in production.
      # Uses secure comparison to prevent timing attacks.
      #
      # @return [void]
      # @raise [KeyError] if API_KEY environment variable is not configured
      # @note Test environment falls back to 'test-api-key-for-test-suite' for convenience
      # @note Renders 401 Unauthorized if API key is missing or invalid
      # @note Renders 500 Internal Server Error if API_KEY is not configured in production
      def authenticate_api_key
        api_key = request.headers["X-API-Key"]

        # Fail hard if API_KEY not set - prevents insecure deployments
        # Test environment falls back to test key for convenience
        expected_key = if Rails.env.test?
          ENV.fetch("API_KEY", "test-api-key-for-test-suite")
        else
          ENV.fetch("API_KEY")
        end

        # For now, we'll use a simple env variable check
        # TODO: Move to proper API key management in database
        unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_key)
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
      rescue KeyError => e
        # Log error and return 500 if API_KEY is not configured
        Rails.logger.error("API_KEY environment variable not set: #{e.message}")
        render json: { error: "Server misconfiguration" }, status: :internal_server_error
      end

      # Paginates an ActiveRecord collection based on page and per_page params.
      # Returns both the paginated data and pagination metadata.
      #
      # @param collection [ActiveRecord::Relation] The collection to paginate
      # @return [Hash] Hash with :data (paginated records) and :meta (pagination info)
      # @note Default page is 1, default per_page is 25, maximum per_page is 100
      # @example
      #   result = paginate(Product.all)
      #   # => {
      #   #   data: [<Product...>],
      #   #   meta: { total: 150, page: 1, per_page: 25, total_pages: 6 }
      #   # }
      def paginate(collection)
        page = params[:page]&.to_i || 1
        per_page = [ params[:per_page]&.to_i || 25, 100 ].min

        paginated = collection.offset((page - 1) * per_page).limit(per_page)
        total_count = collection.count

        {
          data: paginated,
          meta: {
            total: total_count,
            page: page,
            per_page: per_page,
            total_pages: (total_count.to_f / per_page).ceil
          }
        }
      end

      # Convenience method that paginates a collection and renders it as JSON.
      # Combines paginate() with render json: for one-liner usage.
      #
      # @param collection [ActiveRecord::Relation] The collection to paginate and render
      # @return [void]
      # @example
      #   render_paginated(Product.where(status: :active))
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
        if direction.present? && ![ "ASC", "DESC" ].include?(direction)
          render json: { error: "Invalid sort direction. Use ASC or DESC" },
                 status: :bad_request
          return nil
        end

        # Build sanitized sort string
        direction ||= "ASC"
        "#{column} #{direction}"
      end
    end
  end
end
