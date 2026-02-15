module Signals
  # Evaluates a signal against configurable thresholds and promotes to niche if eligible.
  class AutoPromote
    # @param signal [TrendSignal] The signal to evaluate
    # @return [Niche, nil] The newly created niche, or nil if not eligible
    def self.call(signal)
      new(signal).call
    end

    def initialize(signal)
      @signal = signal
    end

    def call
      return nil unless eligible?

      community_type = infer_community_type
      niche = Signals::PromoteToNiche.new(@signal, community_type: community_type).call

      Rails.logger.info("AutoPromote: promoted signal #{@signal.id} '#{@signal.topic}' → niche #{niche.id}")
      niche
    rescue => e
      Rails.logger.error("AutoPromote error for signal #{@signal.id}: #{e.message}")
      nil
    end

    private

    def eligible?
      return false if @signal.status_promoted?
      return false if @signal.momentum_score.nil?
      return false if @signal.momentum_score < momentum_threshold
      return false if signal_age_days < min_age_days

      true
    end

    def signal_age_days
      return 0 unless @signal.first_seen
      (Time.current - @signal.first_seen).to_f / 1.day
    end

    def momentum_threshold
      Setting.find_by(key: "scoring.momentum_score_min")&.value || 5.0
    end

    def min_age_days
      Setting.find_by(key: "scoring.auto_promote_min_age_days")&.value || 2
    end

    def infer_community_type
      raw = @signal.raw_data
      raw = JSON.parse(raw) if raw.is_a?(String) rescue nil
      return "general" unless raw.is_a?(Hash)

      if raw["ao3_enriched"]
        "fandom"
      elsif raw["subreddit"] || raw["subreddits"]
        "reddit_community"
      else
        "general"
      end
    end
  end
end
