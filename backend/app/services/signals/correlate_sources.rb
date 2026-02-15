module Signals
  # Groups signals referring to the same topic across different sources.
  # Uses string normalization first, then AI for uncertain matches.
  class CorrelateSources
    # @param signal [TrendSignal] The signal to correlate
    # @return [TrendSignal, nil] The matched primary signal, or nil
    def self.call(signal)
      new(signal).call
    end

    def initialize(signal)
      @signal = signal
    end

    def call
      return nil if already_correlated?

      # Find candidate signals: active, different source, not already correlated to something else
      candidates = TrendSignal.active
        .where.not(id: @signal.id)
        .where.not(source: @signal.source)
        .where(correlated_signal_id: nil)

      return nil if candidates.empty?

      # Step 1: Normalized string match
      match = find_normalized_match(candidates)

      # Step 2: AI fallback
      match ||= find_ai_match(candidates) if match.nil?

      return nil if match.nil?

      link_signals(match)
      match
    rescue => e
      Rails.logger.error("CorrelateSources error for signal #{@signal.id}: #{e.message}")
      nil
    end

    private

    def already_correlated?
      @signal.correlated_signal_id.present?
    end

    def normalize(text)
      text.downcase
        .gsub(/\b(the|a|an|of|in|on|at|to|for|and|or)\b/, "")
        .gsub(/[^a-z0-9\s]/, "")
        .gsub(/\s+/, " ")
        .strip
    end

    def find_normalized_match(candidates)
      normalized_topic = normalize(@signal.topic)
      return nil if normalized_topic.blank?

      candidates.find { |c| normalize(c.topic) == normalized_topic }
    end

    def find_ai_match(candidates)
      client = Ai::OpenRouterClient.new(task: :cross_correlation)
      return nil unless client.configured?

      candidate_list = candidates.map { |c| "#{c.id}: #{c.topic} (#{c.source})" }.join("\n")

      prompt = <<~PROMPT
        I have a trend signal: "#{@signal.topic}" from #{@signal.source}.

        Which of these signals (if any) refers to the SAME topic/fandom/trend?

        #{candidate_list}

        Rules:
        - Return ONLY the numeric ID of the matching signal
        - If no signal matches, return "NONE"
        - Only match if they clearly refer to the same topic (not just related topics)
        - Consider abbreviations, alternate names, and different formats
      PROMPT

      response = client.complete(
        prompt: prompt,
        system: "You match trend signals that refer to the same topic across different platforms. Return only a number or NONE.",
        temperature: 0.1
      )

      cleaned = response.strip.gsub(/\D/, "")
      return nil if cleaned.blank?

      match_id = cleaned.to_i
      candidates.find { |c| c.id == match_id }
    end

    def link_signals(match)
      # Older signal becomes primary (by first_seen, then by id)
      if (@signal.first_seen || @signal.created_at) < (match.first_seen || match.created_at)
        match.update!(correlated_signal_id: @signal.id)
      else
        @signal.update!(correlated_signal_id: match.id)
      end
    end
  end
end
