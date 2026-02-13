class Niche < ApplicationRecord
  belongs_to :trend_signal
  has_many :cultural_tokens, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true

  enum :status, {
    discovered: "discovered",
    evaluating: "evaluating",
    mining_tokens: "mining_tokens",
    generating_designs: "generating_designs",
    active: "active",
    declining: "declining",
    archived: "archived"
  }, default: :discovered

  scope :by_demand_ratio, -> { order(demand_supply_ratio: :desc) }
  scope :active_pipeline, -> { where(status: [:discovered, :evaluating, :mining_tokens, :generating_designs, :active]) }
end
