# Represents a market niche identified from trend signals.
# Niches are evaluated for their commercial potential based on demand/supply metrics
# from sources like AO3 (fanfiction) and Etsy (marketplace).
#
# @attr [Integer] id Primary key
# @attr [Integer] trend_signal_id Foreign key to TrendSignal
# @attr [String] name Name of the niche
# @attr [Text] description Detailed description of the niche
# @attr [String] community_type Type of community (e.g., 'fandom', 'subculture')
# @attr [Float] demand_score Calculated demand metric
# @attr [Float] supply_score Calculated supply metric
# @attr [Float] demand_supply_ratio Ratio of demand to supply (higher is better)
# @attr [Integer] ao3_works_count Number of fanfiction works on AO3
# @attr [Float] ao3_growth_rate Growth rate of AO3 works
# @attr [Integer] etsy_listing_count Number of similar listings on Etsy
# @attr [String] status Current pipeline status
# @attr [DateTime] discovered_at When the niche was first identified
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class Niche < ApplicationRecord
  belongs_to :trend_signal
  has_many :cultural_tokens, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true

  # Pipeline status tracking niche through discovery to production
  # @note Default status is :discovered
  enum :status, {
    discovered: "discovered",
    evaluating: "evaluating",
    mining_tokens: "mining_tokens",
    generating_designs: "generating_designs",
    active: "active",
    declining: "declining",
    archived: "archived"
  }, default: :discovered

  # @!scope class
  # Returns niches sorted by demand/supply ratio in descending order
  # @return [ActiveRecord::Relation<Niche>] Niches ordered by commercial potential
  scope :by_demand_ratio, -> { order(demand_supply_ratio: :desc) }

  # @!scope class
  # Returns niches currently in the active pipeline
  # @return [ActiveRecord::Relation<Niche>] Niches that are not declining or archived
  scope :active_pipeline, -> { where(status: [:discovered, :evaluating, :mining_tokens, :generating_designs, :active]) }
end
