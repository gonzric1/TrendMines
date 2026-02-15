module Sources
  # Stub for TikTok integration. TikTok requires paid API access or
  # official developer approval. This placeholder returns empty results
  # and indicates the integration is coming soon.
  class Tiktok < Base
    SOURCE_NAME = "TikTok"

    def configured?
      false
    end

    def credential_keys
      %w[tiktok_api_key]
    end

    def scan(topics:)
      []
    end

    def test_connection
      { success: false, message: "TikTok integration coming soon. Requires paid API access or official developer approval." }
    end
  end
end
