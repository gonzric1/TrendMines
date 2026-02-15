module Sources
  # Scans fandomstats.org (AO3 tag statistics) for trending fandoms.
  # No authentication required — public API.
  #
  # API: GET https://fandomstats.org/api/v1.0/stats?tag_id={tag}
  class FandomStats < Base
    API_BASE = "https://fandomstats.org/api/v1.0"
    SOURCE_NAME = "AO3"

    def configured?
      true # No credentials required
    end

    def credential_keys
      []
    end

    # Scans fandom tags for work counts and growth rates.
    #
    # @param topics [Array<String>] Fandom tag names to look up
    # @return [Array<Hash>] Signal results with work counts and growth data
    def scan(topics:)
      results = []

      topics.each do |topic|
        data = fetch_tag_stats(topic)
        next unless data

        works_count = data.dig("works_count") || 0
        growth_rate = calculate_growth_rate(data)

        momentum = calculate_momentum(works_count, growth_rate)
        next if momentum <= 0

        results << build_result(
          source: SOURCE_NAME,
          topic: topic,
          description: "AO3 fandom with #{works_count} works (#{(growth_rate * 100).round(1)}% growth)",
          momentum_score: momentum,
          raw_data: {
            ao3_works: works_count,
            growth_rate: growth_rate,
            bookmarks: data.dig("bookmarks_count"),
            tag_id: data.dig("tag_id")
          }
        )
      rescue => e
        Rails.logger.warn("FandomStats scan error for '#{topic}': #{e.message}")
        next
      end

      results
    end

    # Tests connectivity by fetching stats for a well-known tag.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      data = fetch_tag_stats("Sherlock Holmes")
      if data && data.key?("works_count")
        { success: true, message: "Connected to fandomstats.org (#{data["works_count"]} works for test tag)" }
      else
        { success: false, message: "Unexpected response from fandomstats.org" }
      end
    rescue => e
      { success: false, message: "Connection failed: #{e.message}" }
    end

    private

    def fetch_tag_stats(tag)
      http_get("#{API_BASE}/stats", params: { tag_id: tag })
    rescue RuntimeError => e
      Rails.logger.debug("FandomStats API error for '#{tag}': #{e.message}")
      nil
    end

    def calculate_growth_rate(data)
      # If the API provides historical data, calculate growth; otherwise estimate from metadata
      recent = data.dig("recent_works_count") || 0
      total = data.dig("works_count") || 1
      return 0.0 if total == 0

      # Approximate: recent works as fraction of total indicates activity level
      (recent.to_f / total).round(4)
    end

    def calculate_momentum(works_count, growth_rate)
      # Score 0-10 based on volume and growth
      volume_score = [ Math.log10([ works_count, 1 ].max) / 5.0, 1.0 ].min * 5.0
      growth_score = [ growth_rate * 50, 5.0 ].min
      (volume_score + growth_score).round(2)
    end
  end
end
