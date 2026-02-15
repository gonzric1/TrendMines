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

    # Broad fandom tags to discover from (no user input needed).
    # These are large umbrella tags that reveal which sub-fandoms are active.
    DISCOVERY_TAGS = [
      "Marvel", "DC Comics", "Harry Potter", "Good Omens",
      "Sherlock Holmes", "Doctor Who", "Star Wars", "Star Trek",
      "Supernatural", "The Witcher", "Genshin Impact", "Hades",
      "Baldur's Gate", "Dungeon Meshi", "Frieren", "Jujutsu Kaisen",
      "My Hero Academia", "Chainsaw Man", "Spy x Family",
      "One Piece", "Naruto", "Attack on Titan"
    ].freeze

    # Discovers trending fandoms by scanning broad AO3 tags and extracting
    # which sub-fandoms have the most active communities.
    # No input needed — uses built-in tag list.
    #
    # @return [Array<Hash>] Signal results for active AO3 fandoms
    def discover
      results = []

      DISCOVERY_TAGS.each do |tag|
        data = fetch_tag_stats(tag)
        next unless data
        next if data.key?("message")

        stats = data["stats"] || {}
        fandom_counts = stats["fandom"] || {}

        # Each sub-fandom with significant works is a potential signal
        fandom_counts.each do |fandom_name, count|
          next if count < 500 # Skip tiny fandoms

          category_counts = stats["category"] || {}
          relationship_counts = stats["relationship"] || {}
          freeform_counts = stats["freeform"] || {}

          shipping_count = (category_counts["M/M"] || 0) + (category_counts["F/F"] || 0)
          gen_count = category_counts["Gen"] || 0

          momentum = calculate_momentum(count, shipping_count, gen_count, freeform_counts)
          next if momentum <= 2.0

          results << build_result(
            source: SOURCE_NAME,
            topic: fandom_name,
            description: "AO3: #{count} works in #{fandom_name}",
            momentum_score: momentum,
            raw_data: {
              ao3_works: count,
              parent_tag: tag,
              shipping_ratio: (shipping_count + gen_count) > 0 ? (shipping_count.to_f / (shipping_count + gen_count)).round(3) : 0,
              top_relationships: relationship_counts.first(3).to_h
            }
          )
        end
      rescue => e
        Rails.logger.warn("FandomStats discover error for '#{tag}': #{e.message}")
        next
      end

      # Deduplicate by fandom name, keeping highest momentum
      results
        .group_by { |r| r[:topic].downcase.strip }
        .map { |_key, group| group.max_by { |r| r[:momentum_score] } }
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
