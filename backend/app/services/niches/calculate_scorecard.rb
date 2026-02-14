module Niches
  class CalculateScorecard
    SCORE_COMPONENTS = %w[momentum demand_supply cultural_depth visual_potential uniqueness].freeze

    def initialize(niche)
      @niche = niche
    end

    def call
      weights = load_weights
      scores = compute_raw_scores

      weighted_sum = 0.0
      total_weight = 0.0

      SCORE_COMPONENTS.each do |component|
        weight = weights["#{component}_weight"] || 1
        score = scores[component] || 0.0
        weighted_sum += weight * score
        total_weight += weight
      end

      composite = total_weight > 0 ? (weighted_sum / total_weight).round(2) : 0.0

      {
        composite_score: composite,
        components: scores,
        weights: weights,
        viable: composite >= viability_threshold
      }
    end

    private

    def load_weights
      settings = Setting.where(category: "scoring").index_by(&:key)
      {
        "momentum_weight" => settings.dig("scoring.momentum_weight")&.value || 5,
        "demand_supply_weight" => settings.dig("scoring.demand_supply_weight")&.value || 5,
        "cultural_depth_weight" => settings.dig("scoring.cultural_depth_weight")&.value || 5,
        "visual_potential_weight" => settings.dig("scoring.visual_potential_weight")&.value || 5,
        "uniqueness_weight" => settings.dig("scoring.uniqueness_weight")&.value || 5
      }
    end

    def compute_raw_scores
      signal = @niche.trend_signal
      tokens = @niche.cultural_tokens

      {
        "momentum" => normalize(signal&.momentum_score || 0, 0, 100),
        "demand_supply" => normalize(@niche.demand_supply_ratio || 0, 0, 10),
        "cultural_depth" => tokens.any? ? tokens.average(:composite_score).to_f / 100.0 : 0.0,
        "visual_potential" => tokens.any? ? tokens.average(:visual_potential).to_f / 100.0 : 0.0,
        "uniqueness" => tokens.any? ? tokens.average(:uniqueness_score).to_f / 100.0 : 0.0
      }
    end

    def normalize(value, min, max)
      return 0.0 if max == min
      ((value - min).to_f / (max - min)).clamp(0.0, 1.0).round(4)
    end

    def viability_threshold
      Setting.find_by(key: "scoring.viability_threshold")&.value || 0.6
    end
  end
end
