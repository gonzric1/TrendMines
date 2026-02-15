require "net/http"
require "json"
require "uri"

module Sources
  # Abstract base class for all external signal sources.
  # Provides 3-tier credential lookup, HTTP helpers, and a common interface.
  #
  # Subclasses must implement:
  #   #discover           -> Array of result hashes (find NEW trends, no input needed)
  #   #scan(topics:)      -> Array of result hashes (monitor known topics)
  #   #test_connection    -> { success: Boolean, message: String }
  #   #credential_keys    -> Array of required credential key names
  class Base
    CONNECT_TIMEOUT = 15
    READ_TIMEOUT = 30

    # Discovers new trending topics from this source. No input required.
    # This is the primary method — it finds trends the user doesn't know about yet.
    #
    # @return [Array<Hash>] Array of signal result hashes
    def discover
      []
    end

    # Scans external source for trend data on known topics (monitoring mode).
    #
    # @param topics [Array<String>] Topics to search for
    # @return [Array<Hash>] Array of signal result hashes
    def scan(topics:)
      raise NotImplementedError, "#{self.class}#scan must be implemented"
    end

    # Tests connectivity to the external source.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      raise NotImplementedError, "#{self.class}#test_connection must be implemented"
    end

    # Returns whether all required credentials are present.
    #
    # @return [Boolean]
    def configured?
      credential_keys.all? { |key| credential(key).present? }
    end

    # Returns the list of required credential key names.
    #
    # @return [Array<String>]
    def credential_keys
      []
    end

    protected

    # 3-tier credential lookup: Settings DB (decrypted) -> Rails credentials -> ENV
    #
    # @param key_name [String] The credential key name (e.g. "reddit_client_id")
    # @return [String, nil] The credential value or nil
    def credential(key_name)
      # 1. Settings DB (encrypted)
      setting = Setting.find_by(key: "api_keys.#{key_name}")
      if setting&.value.present?
        decrypted = EncryptedSettingValue.decrypt(setting.value)
        return decrypted if decrypted.present?
      end

      # 2. Rails credentials
      value = Rails.application.credentials.dig(key_name.to_sym)
      return value if value.present?

      # 3. ENV (uppercased)
      ENV[key_name.upcase]
    end

    # Performs an HTTP GET request.
    #
    # @param url [String] Full URL
    # @param headers [Hash] Additional headers
    # @param params [Hash] Query parameters to append
    # @return [Hash] Parsed JSON response
    # @raise [RuntimeError] On non-success HTTP status
    def http_get(url, headers: {}, params: {})
      uri = URI(url)
      uri.query = URI.encode_www_form(params) if params.any?

      request = Net::HTTP::Get.new(uri)
      headers.each { |k, v| request[k] = v }

      execute_request(uri, request)
    end

    # Performs an HTTP POST request.
    #
    # @param url [String] Full URL
    # @param body [Hash, String] Request body (auto-serialized to JSON if Hash)
    # @param headers [Hash] Additional headers
    # @param content_type [String] Content type header
    # @return [Hash] Parsed JSON response
    # @raise [RuntimeError] On non-success HTTP status
    def http_post(url, body: {}, headers: {}, content_type: "application/json")
      uri = URI(url)
      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = content_type
      headers.each { |k, v| request[k] = v }

      request.body = body.is_a?(Hash) ? body.to_json : body

      execute_request(uri, request)
    end

    # Builds a standard result hash for SignalUpsert.
    #
    # @param source [String] Source identifier
    # @param topic [String] Topic name
    # @param description [String] Signal description
    # @param momentum_score [Float] Calculated momentum
    # @param raw_data [Hash] Platform-specific raw data
    # @return [Hash]
    def build_result(source:, topic:, description:, momentum_score:, raw_data: {})
      {
        source: source,
        topic: topic,
        description: description,
        momentum_score: momentum_score,
        raw_data: raw_data
      }
    end

    private

    def execute_request(uri, request)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = CONNECT_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "HTTP #{response.code}: #{response.body&.truncate(500)}"
      end

      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise "Invalid JSON response: #{e.message}"
    end
  end
end
