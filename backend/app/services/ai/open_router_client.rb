require "net/http"
require "json"
require "uri"

module Ai
  # HTTP client wrapping OpenRouter's chat completions API.
  # Uses the same Net::HTTP pattern as Sources::Base.
  class OpenRouterClient
    API_URL = "https://openrouter.ai/api/v1/chat/completions"
    CONNECT_TIMEOUT = 15
    READ_TIMEOUT = 120

    # Maps task names to Setting keys for per-task model selection
    TASK_MODEL_KEYS = {
      token_extraction: "ai.token_extraction_model",
      cross_correlation: "ai.cross_correlation_model",
      ao3_tag_mapping: "ai.ao3_tag_mapping_model"
    }.freeze

    DEFAULT_MODEL = "google/gemini-2.5-flash"

    def initialize(task: nil)
      @task = task
    end

    # Full chat completions call.
    #
    # @param messages [Array<Hash>] Array of {role:, content:} message hashes
    # @param temperature [Float] Sampling temperature (default 0.3)
    # @param max_tokens [Integer] Max response tokens (default 2048)
    # @return [String] The assistant's response text
    def chat(messages:, temperature: 0.3, max_tokens: 2048)
      body = {
        model: resolve_model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }

      response = post_request(body)
      parsed = JSON.parse(response.body)

      choice = parsed.dig("choices", 0, "message", "content")
      raise "Empty response from OpenRouter" if choice.blank?

      choice
    end

    # Convenience method for single-turn completions.
    #
    # @param prompt [String] The user prompt
    # @param system [String, nil] Optional system prompt
    # @param temperature [Float] Sampling temperature
    # @return [String] The assistant's response text
    def complete(prompt:, system: nil, temperature: 0.3)
      messages = []
      messages << { role: "system", content: system } if system.present?
      messages << { role: "user", content: prompt }

      chat(messages: messages, temperature: temperature)
    end

    # Checks if an API key is available from any tier.
    #
    # @return [Boolean]
    def configured?
      resolve_api_key.present?
    end

    # Resolves which model to use: task-specific setting -> default setting -> hardcoded fallback.
    #
    # @return [String] OpenRouter model ID
    def resolve_model
      # 1. Task-specific model
      if @task && TASK_MODEL_KEYS[@task]
        task_model = Setting.find_by(key: TASK_MODEL_KEYS[@task])&.value
        return task_model if task_model.present? && task_model.is_a?(String) && task_model.strip.present?
      end

      # 2. Default model setting
      default = Setting.find_by(key: "ai.default_model")&.value
      return default if default.present? && default.is_a?(String) && default.strip.present?

      # 3. Hardcoded fallback
      DEFAULT_MODEL
    end

    private

    def post_request(body)
      uri = URI(API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = CONNECT_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{resolve_api_key}"
      request["HTTP-Referer"] = "https://trendmines.app"
      request["X-Title"] = "TrendMines"
      request.body = body.to_json

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "OpenRouter API error #{response.code}: #{response.body&.truncate(500)}"
      end

      response
    end

    # 3-tier API key lookup: Settings DB (decrypted) -> Rails credentials -> ENV
    def resolve_api_key
      # 1. Settings DB (encrypted)
      setting = Setting.find_by(key: "api_keys.openrouter_api_key")
      if setting&.value.present?
        decrypted = EncryptedSettingValue.decrypt(setting.value)
        return decrypted if decrypted.present?
      end

      # 2. Rails credentials
      credential = Rails.application.credentials.dig(:openrouter_api_key)
      return credential if credential.present?

      # 3. ENV
      ENV["OPENROUTER_API_KEY"]
    end
  end
end
