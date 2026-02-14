module Api
  module V1
    # API controller for managing application settings.
    # Provides endpoints for reading and updating configuration values
    # (scanning frequencies, scoring weights, alert thresholds, etc.).
    # API keys are managed via Rails credentials, not this endpoint.
    class SettingsController < BaseController
      # Returns all settings grouped by category.
      # API key entries show whether a credential is configured, not the value.
      #
      # @return [JSON] Settings grouped by category, plus api_keys status
      # @example GET /api/v1/settings
      def index
        grouped = Setting.grouped_by_category

        result = grouped.transform_values do |settings|
          settings.map { |s| setting_json(s) }
        end

        result["api_keys"] = api_keys_status

        render json: result
      end

      # Bulk updates settings by key.
      # Wraps all updates in a transaction; rolls back if any validation fails.
      #
      # @param [Hash] settings Key-value pairs to update
      # @return [JSON] List of updated keys (200) or validation errors (422)
      # @example PATCH /api/v1/settings { "settings": { "scanning.ao3_frequency": 24 } }
      def update
        settings_params = params.require(:settings).permit!.to_h
        updated_keys = []
        errors = {}

        ActiveRecord::Base.transaction do
          settings_params.each do |key, val|
            setting = Setting.find_by(key: key)
            unless setting
              errors[key] = ["not found"]
              next
            end

            setting.value = val
            if setting.save
              updated_keys << key
            else
              errors[key] = setting.errors.full_messages
            end
          end

          if errors.any?
            raise ActiveRecord::Rollback
          end
        end

        if errors.any?
          render json: { errors: errors }, status: :unprocessable_entity
        else
          render json: { updated: updated_keys }
        end
      end

      # Returns API key configuration status from Rails credentials.
      # Shows which keys are configured without exposing values.
      #
      # @return [JSON] Array of api key status objects
      # @example GET /api/v1/settings/api_keys
      def api_keys
        render json: api_keys_status
      end

      # Placeholder for connection testing (e.g., verify Etsy API key works).
      #
      # @param [String] service Name of the service to test
      # @return [JSON] Confirmation message
      # @example POST /api/v1/settings/test_connection { "service": "etsy" }
      def test_connection
        service = params[:service] || "unknown"
        render json: { message: "Connection test queued", service: service }
      end

      private

      def setting_json(setting)
        {
          key: setting.key,
          value: setting.value,
          description: setting.description
        }
      end

      # Checks Rails credentials for known API key entries.
      # Returns configured/not-configured status without exposing values.
      API_KEY_CREDENTIALS = %w[etsy_api_key ao3_api_key redbubble_api_key openai_api_key].freeze

      def api_keys_status
        API_KEY_CREDENTIALS.map do |key|
          credential_value = Rails.application.credentials.dig(key.to_sym)
          {
            key: "api_keys.#{key}",
            configured: credential_value.present?,
            description: "#{key.tr('_', ' ').titleize}"
          }
        end
      end
    end
  end
end
