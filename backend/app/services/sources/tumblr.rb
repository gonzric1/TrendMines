module Sources
  # Scans Tumblr for trending tagged content.
  # Uses API key authentication (consumer key in query param).
  #
  # API: GET https://api.tumblr.com/v2/tagged?tag={tag}&api_key={key}
  class Tumblr < Base
    API_BASE = "https://api.tumblr.com/v2"
    SOURCE_NAME = "Tumblr"

    # Purchase-intent phrases that indicate commercial potential
    WISH_PHRASES = [
      "i need this", "i want this", "shut up and take my money",
      "where can i buy", "someone make this", "i would buy",
      "take my money", "need this on a shirt", "need this as a sticker",
      "wish i had", "somebody please make"
    ].freeze

    def credential_keys
      %w[tumblr_consumer_key]
    end

    # Scans Tumblr tags for post activity and purchase-intent signals.
    #
    # @param topics [Array<String>] Tags to search for
    # @return [Array<Hash>] Signal results with note velocity and wish post data
    def scan(topics:)
      return [] unless configured?

      api_key = credential("tumblr_consumer_key")
      results = []

      topics.each do |topic|
        tag = topic.tr(" ", "+")
        posts = fetch_tagged_posts(api_key, tag)
        next if posts.empty?

        total_notes = posts.sum { |p| p.dig("note_count") || 0 }
        avg_notes = posts.length > 0 ? (total_notes.to_f / posts.length).round(1) : 0

        # Calculate note velocity (avg notes per day based on post timestamps)
        note_velocity = calculate_note_velocity(posts)

        # Count posts with purchase-intent language
        wish_count = posts.count { |p| contains_wish_phrase?(p) }

        momentum = calculate_momentum(posts.length, avg_notes, note_velocity, wish_count)

        results << build_result(
          source: SOURCE_NAME,
          topic: topic,
          description: "Tumblr ##{tag}: #{posts.length} recent posts, #{avg_notes} avg notes, #{wish_count} wish posts",
          momentum_score: momentum,
          raw_data: {
            tag: tag,
            post_count: posts.length,
            avg_notes: avg_notes,
            note_velocity: note_velocity,
            wish_post_count: wish_count
          }
        )
      rescue => e
        Rails.logger.warn("Tumblr scan error for '#{topic}': #{e.message}")
        next
      end

      results
    end

    # Tests Tumblr API connectivity by fetching a popular tag.
    #
    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      return { success: false, message: "Tumblr consumer key not configured" } unless configured?

      api_key = credential("tumblr_consumer_key")
      posts = fetch_tagged_posts(api_key, "art")

      if posts.any?
        { success: true, message: "Connected to Tumblr API (#{posts.length} posts for test tag)" }
      else
        { success: false, message: "Tumblr API returned no results for test tag" }
      end
    rescue => e
      { success: false, message: "Tumblr connection failed: #{e.message}" }
    end

    private

    def fetch_tagged_posts(api_key, tag, limit: 20)
      data = http_get("#{API_BASE}/tagged", params: {
        tag: tag,
        api_key: api_key,
        limit: limit
      })
      data.dig("response") || []
    rescue RuntimeError => e
      Rails.logger.debug("Tumblr API error for tag '#{tag}': #{e.message}")
      []
    end

    def calculate_note_velocity(posts)
      return 0.0 if posts.empty?

      now = Time.current.to_i
      velocities = posts.filter_map do |post|
        timestamp = post["timestamp"]
        next unless timestamp
        age_days = [(now - timestamp) / 86400.0, 0.01].max
        notes = post["note_count"] || 0
        notes / age_days
      end

      return 0.0 if velocities.empty?
      (velocities.sum / velocities.length).round(2)
    end

    def contains_wish_phrase?(post)
      text = [
        post.dig("summary"),
        post.dig("body"),
        post.dig("caption")
      ].compact.join(" ").downcase

      WISH_PHRASES.any? { |phrase| text.include?(phrase) }
    end

    def calculate_momentum(post_count, avg_notes, velocity, wish_count)
      volume_score = [post_count.to_f / 5, 3.0].min
      engagement_score = [avg_notes / 100.0, 3.0].min
      velocity_score = [velocity / 50.0, 2.0].min
      wish_score = [wish_count.to_f / 2, 2.0].min

      (volume_score + engagement_score + velocity_score + wish_score).round(2)
    end
  end
end
