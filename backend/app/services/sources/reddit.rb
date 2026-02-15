module Sources
  # Scans Reddit for trending content using the OAuth2 API.
  # Requires reddit_client_id and reddit_client_secret credentials.
  #
  # Token exchange: POST https://www.reddit.com/api/v1/access_token
  # API base: https://oauth.reddit.com
  class Reddit < Base
    TOKEN_URL = "https://www.reddit.com/api/v1/access_token"
    API_BASE = "https://oauth.reddit.com"
    SOURCE_NAME = "Reddit"
    USER_AGENT = "TrendMines/1.0 (Signal Scanner)"

    def credential_keys
      %w[reddit_client_id reddit_client_secret]
    end

    # Scans Reddit for rising/trending content related to given topics.
    #
    # @param topics [Array<String>] Topics to search subreddits for
    # @return [Array<Hash>] Signal results with subreddit activity data
    def scan(topics:)
      return [] unless configured?

      token = fetch_access_token
      results = []

      topics.each do |topic|
        subreddits = search_subreddits(token, topic)
        next if subreddits.empty?

        subreddits.first(3).each do |sub|
          sub_name = sub.dig("data", "display_name")
          next unless sub_name

          rising = fetch_rising(token, sub_name)
          top_weekly = fetch_top_weekly(token, sub_name)

          subscribers = sub.dig("data", "subscribers") || 0
          active_users = sub.dig("data", "accounts_active") || 0
          rising_count = rising.dig("data", "children")&.length || 0
          top_score = top_weekly.dig("data", "children")&.first&.dig("data", "score") || 0

          momentum = calculate_momentum(subscribers, active_users, rising_count, top_score)

          results << build_result(
            source: SOURCE_NAME,
            topic: topic,
            description: "r/#{sub_name}: #{subscribers} subscribers, #{active_users} active, #{rising_count} rising posts",
            momentum_score: momentum,
            raw_data: {
              subreddit: sub_name,
              subscribers: subscribers,
              active_users: active_users,
              rising_posts: rising_count,
              top_weekly_score: top_score
            }
          )
        end
      rescue => e
        Rails.logger.warn("Reddit scan error for '#{topic}': #{e.message}")
        next
      end

      results
    end

    # Tests Reddit API connectivity by fetching user identity.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      return { success: false, message: "Reddit credentials not configured" } unless configured?

      token = fetch_access_token
      data = api_get(token, "/api/v1/me")
      { success: true, message: "Authenticated as application (rate limit: #{data.dig("subreddit", "subscribers") || "OK"})" }
    rescue => e
      { success: false, message: "Reddit connection failed: #{e.message}" }
    end

    private

    def fetch_access_token
      cache_key = "sources/reddit/access_token"
      cached = Rails.cache.read(cache_key)
      return cached if cached.present?

      client_id = credential("reddit_client_id")
      client_secret = credential("reddit_client_secret")

      uri = URI(TOKEN_URL)
      request = Net::HTTP::Post.new(uri)
      request.basic_auth(client_id, client_secret)
      request["User-Agent"] = USER_AGENT
      request.set_form_data(grant_type: "client_credentials")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = CONNECT_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      response = http.request(request)
      unless response.is_a?(Net::HTTPSuccess)
        raise "Reddit auth failed (#{response.code}): #{response.body&.truncate(200)}"
      end

      data = JSON.parse(response.body)
      token = data["access_token"]
      raise "No access_token in Reddit response" unless token.present?

      Rails.cache.write(cache_key, token, expires_in: 55.minutes)
      token
    end

    def api_get(token, path, params: {})
      url = "#{API_BASE}#{path}"
      http_get(url, headers: {
        "Authorization" => "Bearer #{token}",
        "User-Agent" => USER_AGENT
      }, params: params)
    end

    def search_subreddits(token, query)
      data = api_get(token, "/subreddits/search", params: { q: query, limit: 5 })
      data.dig("data", "children") || []
    rescue => e
      Rails.logger.debug("Reddit subreddit search failed for '#{query}': #{e.message}")
      []
    end

    def fetch_rising(token, subreddit)
      api_get(token, "/r/#{subreddit}/rising", params: { limit: 10 })
    rescue => e
      Rails.logger.debug("Reddit rising fetch failed for r/#{subreddit}: #{e.message}")
      { "data" => { "children" => [] } }
    end

    def fetch_top_weekly(token, subreddit)
      api_get(token, "/r/#{subreddit}/top", params: { t: "week", limit: 5 })
    rescue => e
      Rails.logger.debug("Reddit top fetch failed for r/#{subreddit}: #{e.message}")
      { "data" => { "children" => [] } }
    end

    def calculate_momentum(subscribers, active_users, rising_count, top_score)
      # Weighted momentum: activity ratio + rising content + engagement
      activity_ratio = subscribers > 0 ? (active_users.to_f / subscribers * 100) : 0
      activity_score = [activity_ratio, 5.0].min

      rising_score = [rising_count.to_f / 2, 3.0].min
      engagement_score = [Math.log10([top_score, 1].max) / 2, 2.0].min

      (activity_score + rising_score + engagement_score).round(2)
    end
  end
end
