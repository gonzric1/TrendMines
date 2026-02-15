module Sources
  # Scans Google Trends data via SerpAPI for breakout terms and rising queries.
  #
  # API: GET https://serpapi.com/search?engine=google_trends&q={topic}&api_key={key}
  class GoogleTrends < Base
    API_BASE = "https://serpapi.com/search"
    SOURCE_NAME = "Google Trends"

    def credential_keys
      %w[serpapi_api_key]
    end

    # Scans Google Trends for interest data and related queries.
    # Returns empty array if not configured (graceful skip).
    #
    # @param topics [Array<String>] Topics to query
    # @return [Array<Hash>] Signal results with trend interest data
    def scan(topics:)
      return [] unless configured?

      api_key = credential("serpapi_api_key")
      results = []

      topics.each do |topic|
        data = fetch_trends(api_key, topic)
        next unless data

        interest = extract_interest_over_time(data)
        related = extract_related_queries(data)
        breakout_terms = related.select { |q| q[:type] == "breakout" }

        momentum = calculate_momentum(interest, related, breakout_terms)

        results << build_result(
          source: SOURCE_NAME,
          topic: topic,
          description: "Google Trends: #{breakout_terms.length} breakout terms, interest avg #{interest[:average]}",
          momentum_score: momentum,
          raw_data: {
            interest_over_time: interest,
            related_queries: related,
            breakout_count: breakout_terms.length
          }
        )
      rescue => e
        Rails.logger.warn("GoogleTrends scan error for '#{topic}': #{e.message}")
        next
      end

      results
    end

    # Tests SerpAPI connectivity by querying a known term.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      return { success: false, message: "SerpAPI key not configured" } unless configured?

      api_key = credential("serpapi_api_key")
      data = fetch_trends(api_key, "hello world")

      if data
        { success: true, message: "Connected to SerpAPI Google Trends" }
      else
        { success: false, message: "SerpAPI returned no data for test query" }
      end
    rescue => e
      { success: false, message: "SerpAPI connection failed: #{e.message}" }
    end

    private

    def fetch_trends(api_key, topic)
      http_get(API_BASE, params: {
        engine: "google_trends",
        q: topic,
        api_key: api_key
      })
    rescue RuntimeError => e
      Rails.logger.debug("SerpAPI error for '#{topic}': #{e.message}")
      nil
    end

    def extract_interest_over_time(data)
      timeline = data.dig("interest_over_time", "timeline_data") || []
      values = timeline.filter_map { |point| point.dig("values", 0, "extracted_value") }

      return { average: 0, max: 0, trend: "flat", values: [] } if values.empty?

      avg = (values.sum.to_f / values.length).round(1)
      max = values.max

      # Determine trend direction from last third vs first third
      third = [values.length / 3, 1].max
      first_avg = values.first(third).sum.to_f / third
      last_avg = values.last(third).sum.to_f / third
      trend = if last_avg > first_avg * 1.2
        "rising"
      elsif last_avg < first_avg * 0.8
        "declining"
      else
        "stable"
      end

      { average: avg, max: max, trend: trend, values: values.last(12) }
    end

    def extract_related_queries(data)
      rising = data.dig("related_queries", "rising") || []
      top = data.dig("related_queries", "top") || []

      queries = []

      rising.each do |q|
        value = q.dig("extracted_value") || q.dig("value") || 0
        queries << {
          query: q["query"],
          value: value,
          type: value.to_s.downcase.include?("breakout") ? "breakout" : "rising"
        }
      end

      top.each do |q|
        queries << {
          query: q["query"],
          value: q.dig("extracted_value") || q.dig("value") || 0,
          type: "top"
        }
      end

      queries
    end

    def calculate_momentum(interest, related, breakout_terms)
      # Interest score (0-4): average interest normalized
      interest_score = [interest[:average] / 25.0, 4.0].min

      # Trend bonus (0-2): rising trends get bonus
      trend_bonus = case interest[:trend]
      when "rising" then 2.0
      when "stable" then 1.0
      else 0.0
      end

      # Breakout score (0-2): each breakout term adds signal
      breakout_score = [breakout_terms.length.to_f / 2, 2.0].min

      # Related query depth (0-2): more related = broader interest
      depth_score = [related.length.to_f / 10, 2.0].min

      (interest_score + trend_bonus + breakout_score + depth_score).round(2)
    end
  end
end
