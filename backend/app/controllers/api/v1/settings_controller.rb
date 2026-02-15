module Api
  module V1
    # API controller for managing application settings.
    # Provides endpoints for reading and updating configuration values
    # (scanning frequencies, scoring weights, alert thresholds, etc.).
    # API keys can be saved encrypted in the DB, or read from Rails credentials / ENV.
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

        # Remove raw api_keys category (encrypted blobs) — replace with status view
        result.delete("api_keys")
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

      # Returns API key configuration status.
      # Shows which keys are configured and their source without exposing values.
      #
      # @return [JSON] Array of api key status objects
      # @example GET /api/v1/settings/api_keys
      def api_keys
        render json: api_keys_status
      end

      # Saves API keys encrypted in the Settings table.
      # Receives plaintext values, encrypts them, and upserts into the api_keys category.
      #
      # @param [Hash] api_keys Key-value pairs of API key names to plaintext values
      # @return [JSON] List of saved keys
      # @example PATCH /api/v1/settings/api_keys { "api_keys": { "reddit_client_id": "abc" } }
      def update_api_keys
        keys_params = params.require(:api_keys).permit!.to_h
        saved_keys = []

        keys_params.each do |key_name, plaintext|
          next if plaintext.blank?
          next unless API_KEY_DEFINITIONS.key?(key_name)

          encrypted = EncryptedSettingValue.encrypt(plaintext)
          setting = Setting.find_or_initialize_by(key: "api_keys.#{key_name}")
          setting.category = "api_keys"
          setting.value = encrypted
          setting.description = API_KEY_DEFINITIONS[key_name][:description]
          setting.save!
          saved_keys << key_name
        end

        render json: { saved: saved_keys }
      end

      # Tests connection for a service group by instantiating its source service.
      #
      # @param [String] service Name of the service group to test
      # @return [JSON] Connection test result
      # @example POST /api/v1/settings/test_connection { "service": "reddit" }
      def test_connection
        service = params[:service].to_s

        class_name = SOURCE_SERVICE_MAP[service]
        unless class_name
          render json: { success: false, message: "Unknown service: #{service}", service: service }
          return
        end

        instance = class_name.constantize.new
        result = instance.test_connection
        render json: result.merge(service: service)
      rescue => e
        render json: { success: false, message: e.message, service: service }
      end

      private

      def setting_json(setting)
        {
          key: setting.key,
          value: setting.value,
          description: setting.description
        }
      end

      # Maps API key names to their descriptions and service groups.
      API_KEY_DEFINITIONS = {
        "reddit_client_id" => { description: "Reddit OAuth Client ID", group: "reddit" },
        "reddit_client_secret" => { description: "Reddit OAuth Client Secret", group: "reddit" },
        "tumblr_consumer_key" => { description: "Tumblr Consumer Key", group: "tumblr" },
        "serpapi_api_key" => { description: "SerpAPI Key (Google Trends)", group: "google_trends" },
        "gemini_api_key" => { description: "Google Gemini API Key", group: "gemini" }
      }.freeze

      # Maps service group names to their source service class names (constantized at runtime).
      SOURCE_SERVICE_MAP = {
        "reddit" => "Sources::Reddit",
        "tumblr" => "Sources::Tumblr",
        "google_trends" => "Sources::GoogleTrends",
        "gemini" => "Sources::GoogleTrends",
        "ao3" => "Sources::FandomStats",
        "tiktok" => "Sources::Tiktok"
      }.freeze

      # 3-tier lookup: Settings DB (decrypted) -> Rails credentials -> ENV
      def resolve_api_key(key_name)
        # 1. Settings DB
        setting = Setting.find_by(key: "api_keys.#{key_name}")
        if setting&.value.present?
          decrypted = EncryptedSettingValue.decrypt(setting.value)
          return { value: decrypted, source: "database" } if decrypted.present?
        end

        # 2. Rails credentials
        credential = Rails.application.credentials.dig(key_name.to_sym)
        return { value: credential, source: "credentials" } if credential.present?

        # 3. ENV
        env_val = ENV[key_name.upcase]
        return { value: env_val, source: "env" } if env_val.present?

        { value: nil, source: nil }
      end

      def api_keys_status
        API_KEY_DEFINITIONS.map do |key_name, meta|
          resolved = resolve_api_key(key_name)
          configured = resolved[:value].present?

          masked = if configured && resolved[:value].is_a?(String) && resolved[:value].length > 4
            "#{resolved[:value][0..3]}#{"*" * [resolved[:value].length - 4, 20].min}"
          elsif configured
            "****"
          end

          {
            key: key_name,
            configured: configured,
            source: resolved[:source],
            masked_value: masked,
            description: meta[:description],
            group: meta[:group]
          }
        end
      end
    end
  end
end
