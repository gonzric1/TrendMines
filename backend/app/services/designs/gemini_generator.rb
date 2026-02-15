module Designs
  class GeminiGenerator
    GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"

    def initialize
      @api_key = resolve_gemini_key
    end

    def generate(prompt:, style: nil)
      raise "Gemini API key not configured" unless @api_key.present?

      full_prompt = build_prompt(prompt, style)
      response = call_api(full_prompt)
      parse_response(response)
    end

    private

    def build_prompt(prompt, style)
      composer = Prompts::TemplateComposer.new(style: style || "default")
      composer.compose(prompt)
    end

    def call_api(prompt)
      uri = URI("#{GEMINI_API_URL}?key=#{@api_key}")

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request.body = {
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { temperature: 0.7 }
      }.to_json

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 30
      http.read_timeout = 60

      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Gemini API error (#{response.code}): #{response.body}"
      end

      JSON.parse(response.body)
    end

    # 3-tier credential lookup: Settings DB (encrypted) -> Rails credentials -> ENV
    def resolve_gemini_key
      # 1. Settings DB
      setting = Setting.find_by(key: "api_keys.gemini_api_key")
      if setting&.value.present?
        decrypted = EncryptedSettingValue.decrypt(setting.value)
        return decrypted if decrypted.present?
      end

      # 2. Rails credentials
      credential = Rails.application.credentials.dig(:gemini_api_key)
      return credential if credential.present?

      # 3. ENV
      ENV["GEMINI_API_KEY"]
    end

    def parse_response(response)
      candidates = response.dig("candidates")
      raise "No candidates in Gemini response" unless candidates&.any?

      content = candidates.first.dig("content", "parts", 0, "text")
      {
        content: content,
        model: "gemini-2.0-flash-exp",
        usage: response.dig("usageMetadata"),
        estimated_cost: 0.0
      }
    end
  end
end
