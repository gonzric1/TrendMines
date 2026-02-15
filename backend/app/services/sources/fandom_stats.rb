module Sources
  # Scans fandomstats.org (AO3 tag statistics) for trending fandoms.
  # No authentication required — public API.
  #
  # API: GET https://fandomstats.org/api/v1.0/stats?tag_id={tag}
  # Returns: { numworks: Int, stats: { rating: {}, category: {}, fandom: {}, character: {}, relationship: {}, freeform: {} } }
  class FandomStats < Base
    API_BASE = "https://fandomstats.org/api/v1.0"
    SOURCE_NAME = "AO3"

    def configured?
      true # No credentials required
    end

    def credential_keys
      []
    end

    # Discovery disabled — FandomStats is used for enrichment only.
    # Signals are discovered by Reddit, Tumblr, and Google Trends.
    def discover
      []
    end

    # Scans fandom tags for work counts and engagement breakdowns.
    #
    # @param topics [Array<String>] Fandom tag names to look up
    # @return [Array<Hash>] Signal results with work counts and fandom data
    def scan(topics:)
      results = []

      topics.each do |topic|
        data = fetch_tag_stats(topic)
        next unless data
        next if data.key?("message") # API error response

        stats = data["stats"] || {}
        num_works = data["numworks"] || 0

        # Calculate total works from fandom breakdown if numworks is 0
        fandom_counts = stats["fandom"] || {}
        total_from_fandoms = fandom_counts.values.sum
        works_count = num_works > 0 ? num_works : total_from_fandoms

        # Extract engagement signals from the data
        category_counts = stats["category"] || {}
        relationship_counts = stats["relationship"] || {}
        freeform_counts = stats["freeform"] || {}

        # M/M and F/F content signals strong fandom engagement
        shipping_count = (category_counts["M/M"] || 0) + (category_counts["F/F"] || 0)
        gen_count = category_counts["Gen"] || 0

        momentum = calculate_momentum(works_count, shipping_count, gen_count, freeform_counts)
        next if momentum <= 0

        top_relationships = relationship_counts.first(5).map { |k, v| { name: k, count: v } }
        top_freeform = freeform_counts.first(5).map { |k, v| { tag: k, count: v } }

        results << build_result(
          source: SOURCE_NAME,
          topic: topic,
          description: "AO3 fandom: #{works_count} works across #{fandom_counts.length} sub-fandoms",
          momentum_score: momentum,
          raw_data: {
            ao3_works: works_count,
            fandom_count: fandom_counts.length,
            top_fandoms: fandom_counts.first(5).to_h,
            shipping_ratio: works_count > 0 ? (shipping_count.to_f / works_count).round(3) : 0,
            top_relationships: top_relationships,
            top_freeform_tags: top_freeform,
            category_breakdown: category_counts
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
      if data && data.key?("stats")
        fandom_counts = data.dig("stats", "fandom") || {}
        total = fandom_counts.values.sum
        { success: true, message: "Connected to fandomstats.org (#{total} works across #{fandom_counts.length} fandoms for test tag)" }
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

    def calculate_momentum(works_count, shipping_count, gen_count, freeform_counts)
      return 0.0 if works_count == 0

      # Volume score (0-4): log-scaled work count
      volume_score = [Math.log10([works_count, 1].max) / 1.5, 4.0].min

      # Engagement score (0-3): shipping ratio indicates passionate fandom
      total_categorized = shipping_count + gen_count
      shipping_ratio = total_categorized > 0 ? shipping_count.to_f / total_categorized : 0
      engagement_score = [shipping_ratio * 3.0, 3.0].min

      # Freeform diversity (0-3): more freeform tags = more active community
      freeform_total = freeform_counts.values.sum
      freeform_score = [Math.log10([freeform_total, 1].max) / 2.0, 3.0].min

      (volume_score + engagement_score + freeform_score).round(2)
    end
  end
end
