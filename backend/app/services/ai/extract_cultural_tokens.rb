module Ai
  # Uses OpenRouter AI to extract cultural tokens from a niche's signal data.
  # Creates CulturalToken records with scores.
  class ExtractCulturalTokens
    VALID_TOKEN_TYPES = %w[phrase quote symbol character meme reference catchphrase].freeze

    # @param niche [Niche] The niche to extract tokens for
    # @return [Array<CulturalToken>] Created token records
    def self.call(niche)
      new(niche).call
    end

    def initialize(niche)
      @niche = niche
    end

    def call
      client = Ai::OpenRouterClient.new(task: :token_extraction)
      return [] unless client.configured?

      raw_context = aggregate_raw_data
      return [] if raw_context.blank?

      response = client.complete(
        prompt: build_prompt(raw_context),
        system: system_prompt,
        temperature: 0.4
      )

      tokens_data = parse_response(response)
      create_tokens(tokens_data)
    rescue => e
      Rails.logger.error("ExtractCulturalTokens error for niche #{@niche.id}: #{e.message}")
      []
    end

    private

    def aggregate_raw_data
      signal = @niche.trend_signal
      return {} unless signal

      # Collect raw_data from all correlated signals
      all_signals = signal.respond_to?(:correlation_group) ? signal.correlation_group : [signal]
      merged = {}

      all_signals.each do |s|
        raw = s.raw_data
        raw = JSON.parse(raw) if raw.is_a?(String)
        next unless raw.is_a?(Hash)
        merged.merge!(raw) { |_key, old, new_val| old } # Keep first occurrence
      end

      merged
    end

    def system_prompt
      <<~SYSTEM
        You are an expert at identifying culturally significant elements within fan communities and subcultures.
        Your job is to extract sellable cultural tokens — phrases, quotes, symbols, memes, and character references
        that fans would want on merchandise (magnets, stickers, prints).
      SYSTEM
    end

    def build_prompt(raw_context)
      <<~PROMPT
        Analyze this trend/fandom data and extract cultural tokens suitable for merchandise:

        Topic: #{@niche.name}
        Community Type: #{@niche.community_type}
        Raw Data: #{raw_context.to_json}

        Return a JSON array of tokens. Each token should have:
        - "value": the phrase/quote/symbol/character name (string)
        - "token_type": one of #{VALID_TOKEN_TYPES.join(", ")} (string)
        - "emotional_intensity": how emotionally resonant (0-100 integer)
        - "frequency_score": how often referenced in the community (0-100 integer)
        - "uniqueness_score": how unique to this community (0-100 integer)
        - "visual_potential": how well it translates to visual design (0-100 integer)
        - "context": brief explanation of cultural significance (string)

        Return 5-10 tokens, ranked by commercial potential.
        Return ONLY the JSON array, no markdown, no explanation.
      PROMPT
    end

    def parse_response(response)
      # Strip markdown code fences if present
      cleaned = response.strip
      cleaned = cleaned.gsub(/\A```(?:json)?\s*/, "").gsub(/\s*```\z/, "")

      JSON.parse(cleaned)
    rescue JSON::ParserError => e
      Rails.logger.error("ExtractCulturalTokens: JSON parse error: #{e.message}")
      []
    end

    def create_tokens(tokens_data)
      return [] unless tokens_data.is_a?(Array)

      tokens_data.filter_map do |data|
        next unless data.is_a?(Hash) && data["value"].present?

        token_type = VALID_TOKEN_TYPES.include?(data["token_type"]) ? data["token_type"] : "phrase"

        scores = {
          emotional_intensity: clamp_score(data["emotional_intensity"]),
          frequency_score: clamp_score(data["frequency_score"]),
          uniqueness_score: clamp_score(data["uniqueness_score"]),
          visual_potential: clamp_score(data["visual_potential"])
        }

        composite = scores.values.sum.to_f / scores.length

        @niche.cultural_tokens.create!(
          token_type: token_type,
          value: data["value"],
          status: "extracted",
          composite_score: composite.round(1),
          frequency_score: scores[:frequency_score],
          emotional_intensity: scores[:emotional_intensity],
          visual_potential: scores[:visual_potential],
          uniqueness_score: scores[:uniqueness_score],
          source_references: { context: data["context"], extracted_by: "openrouter_ai" }
        )
      rescue => e
        Rails.logger.error("ExtractCulturalTokens: failed to create token '#{data["value"]}': #{e.message}")
        nil
      end
    end

    def clamp_score(value)
      return 50.0 unless value.is_a?(Numeric)
      value.to_f.clamp(0.0, 100.0)
    end
  end
end
