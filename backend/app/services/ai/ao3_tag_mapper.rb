module Ai
  # Maps a topic string to its canonical AO3 tag using direct lookup + AI fallback.
  # Returns the verified AO3 tag or nil if no valid mapping found.
  class Ao3TagMapper
    # @param topic [String] The topic to map to an AO3 tag
    # @return [String, nil] The canonical AO3 tag, or nil if unmappable
    def self.call(topic)
      new(topic).call
    end

    def initialize(topic)
      @topic = topic
      @scanner = Sources::FandomStats.new
    end

    def call
      # Step 1: Direct lookup — topic as-is
      if direct_match?(@topic)
        return @topic
      end

      # Step 2: AI suggestion
      ai_client = Ai::OpenRouterClient.new(task: :ao3_tag_mapping)
      return nil unless ai_client.configured?

      suggested = ask_ai(ai_client)
      return nil if suggested.blank?

      # Step 3: Verify AI suggestion actually exists on AO3
      if direct_match?(suggested)
        suggested
      else
        Rails.logger.info("Ao3TagMapper: AI suggested '#{suggested}' for '#{@topic}' but it wasn't found on AO3")
        nil
      end
    rescue => e
      Rails.logger.error("Ao3TagMapper error for '#{@topic}': #{e.message}")
      nil
    end

    private

    def direct_match?(tag)
      results = @scanner.scan(topics: [tag])
      results.any?
    end

    def ask_ai(client)
      prompt = <<~PROMPT
        What is the canonical AO3 (Archive of Our Own) fandom tag for: "#{@topic}"?

        Rules:
        - Return ONLY the exact AO3 tag name, nothing else
        - If you're not sure, return "NONE"
        - AO3 tags often include the media type, e.g. "Sherlock (BBC TV 2010)" not just "Sherlock"
        - Common abbreviations: BNHA = "僕のヒーローアカデミア | Boku no Hero Academia | My Hero Academia", MHA = same
        - Return the most commonly used version of the tag
      PROMPT

      response = client.complete(
        prompt: prompt,
        system: "You are an expert on Archive of Our Own (AO3) fandom tagging conventions. Return only the tag name.",
        temperature: 0.1
      )

      cleaned = response.strip.gsub(/\A["']|["']\z/, "")
      cleaned == "NONE" ? nil : cleaned
    end
  end
end
