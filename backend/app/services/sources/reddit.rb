module Sources
  # Scans Reddit for trending fandom and merch content using the OAuth2 API.
  # Requires reddit_client_id and reddit_client_secret credentials.
  #
  # Discovery mode: crawls fandom/merch subreddits for rising trends.
  # Monitoring mode: searches for specific topics across Reddit.
  class Reddit < Base
    TOKEN_URL = "https://www.reddit.com/api/v1/access_token"
    API_BASE = "https://oauth.reddit.com"
    SOURCE_NAME = "Reddit"
    USER_AGENT = "TrendMines/1.0 (Signal Scanner)"

    # Subreddits to crawl for trend discovery (no user input needed)
    DISCOVERY_SUBREDDITS = %w[
      fandom fanart printmaking stickers etsysellers
      shutupandtakemymoney ineedthis didntknowiwantedthat
      anime manga cosplay bookish booktok
      popculture television movies gaming
    ].freeze

    def credential_keys
      %w[reddit_client_id reddit_client_secret]
    end

    # Discovers trending topics from fandom/merch subreddits.
    # No input needed — crawls rising and hot posts to find what's trending.
    #
    # @return [Array<Hash>] Signal results discovered from Reddit
    def discover
      return [] unless configured?

      token = fetch_access_token
      results = []

      DISCOVERY_SUBREDDITS.each do |sub_name|
        posts = fetch_hot(token, sub_name)
        children = posts.dig("data", "children") || []
        next if children.empty?

        # Group posts by topic (extract meaningful phrases from titles)
        topic_signals = extract_topics_from_posts(children, sub_name)
        results.concat(topic_signals)
      rescue => e
        Rails.logger.warn("Reddit discover error for r/#{sub_name}: #{e.message}")
        next
      end

      # Deduplicate by topic, keeping highest momentum
      dedupe_results(results)
    end

    # Scans Reddit for specific known topics.
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
          subscribers = sub.dig("data", "subscribers") || 0
          active_users = sub.dig("data", "accounts_active") || 0
          rising_count = rising.dig("data", "children")&.length || 0

          momentum = calculate_subreddit_momentum(subscribers, active_users, rising_count)

          results << build_result(
            source: SOURCE_NAME,
            topic: topic,
            description: "r/#{sub_name}: #{subscribers} subscribers, #{active_users} active, #{rising_count} rising",
            momentum_score: momentum,
            raw_data: {
              subreddit: sub_name,
              subscribers: subscribers,
              active_users: active_users,
              rising_posts: rising_count
            }
          )
        end
      rescue => e
        Rails.logger.warn("Reddit scan error for '#{topic}': #{e.message}")
        next
      end

      results
    end

    # Tests Reddit API connectivity.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      return { success: false, message: "Reddit credentials not configured" } unless configured?

      token = fetch_access_token
      api_get(token, "/api/v1/me")
      { success: true, message: "Reddit API authenticated successfully" }
    rescue => e
      { success: false, message: "Reddit connection failed: #{e.message}" }
    end

    private

    # Extracts trending topics from a subreddit's hot posts
    def extract_topics_from_posts(children, subreddit)
      results = []

      # Look at high-engagement posts
      hot_posts = children.select do |post|
        score = post.dig("data", "score") || 0
        comments = post.dig("data", "num_comments") || 0
        score > 50 || comments > 20
      end

      hot_posts.first(10).each do |post|
        data = post["data"] || {}
        title = data["title"].to_s
        score = data["score"] || 0
        comments = data["num_comments"] || 0
        upvote_ratio = data["upvote_ratio"] || 0.5

        # Extract the topic: use flair first, then clean the title
        topic = data["link_flair_text"].presence || extract_topic_from_title(title)
        next if topic.blank? || topic.length < 3 || topic.length > 100

        momentum = calculate_post_momentum(score, comments, upvote_ratio)
        next if momentum < 2.0

        results << build_result(
          source: SOURCE_NAME,
          topic: topic,
          description: "Trending on r/#{subreddit}: \"#{title.truncate(80)}\" (#{score} upvotes, #{comments} comments)",
          momentum_score: momentum,
          raw_data: {
            subreddit: subreddit,
            post_title: title,
            score: score,
            num_comments: comments,
            upvote_ratio: upvote_ratio
          }
        )
      end

      results
    end

    # Cleans a post title into a usable topic name
    def extract_topic_from_title(title)
      # Remove common Reddit noise
      cleaned = title
        .gsub(/\[.*?\]/, "") # [OC], [Fan Art], etc.
        .gsub(/\(.*?\)/, "") # (description)
        .gsub(/https?:\/\/\S+/, "") # URLs
        .gsub(/[^\w\s'-]/, " ") # special chars
        .strip
        .split(/\s+/)
        .first(6) # Keep it short
        .join(" ")
        .strip

      cleaned.length >= 3 ? cleaned : nil
    end

    def calculate_post_momentum(score, comments, upvote_ratio)
      score_component = [Math.log10([score, 1].max) / 1.0, 4.0].min
      comment_component = [Math.log10([comments, 1].max) / 0.8, 3.0].min
      ratio_bonus = upvote_ratio > 0.9 ? 1.5 : (upvote_ratio > 0.8 ? 1.0 : 0.5)
      (score_component + comment_component + ratio_bonus).round(2)
    end

    def calculate_subreddit_momentum(subscribers, active_users, rising_count)
      activity_ratio = subscribers > 0 ? (active_users.to_f / subscribers * 100) : 0
      activity_score = [activity_ratio, 5.0].min
      rising_score = [rising_count.to_f / 2, 3.0].min
      (activity_score + rising_score).round(2)
    end

    # Deduplicates results, keeping the highest momentum per topic
    def dedupe_results(results)
      results
        .group_by { |r| r[:topic].downcase.strip }
        .map { |_key, group| group.max_by { |r| r[:momentum_score] } }
    end

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

    def fetch_hot(token, subreddit)
      api_get(token, "/r/#{subreddit}/hot", params: { limit: 25 })
    rescue => e
      Rails.logger.debug("Reddit hot fetch failed for r/#{subreddit}: #{e.message}")
      { "data" => { "children" => [] } }
    end
  end
end
