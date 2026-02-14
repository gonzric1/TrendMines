module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_api_key

      private

      def authenticate_api_key
        api_key = request.headers['X-API-Key']
        expected_key = ENV.fetch('API_KEY', 'dev-api-key-change-in-production')

        # For now, we'll use a simple env variable check
        # TODO: Move to proper API key management in database
        unless api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, expected_key)
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
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
    end
  end
end
