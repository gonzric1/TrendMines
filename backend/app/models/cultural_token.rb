class CulturalToken < ApplicationRecord
  belongs_to :niche
  has_many :designs, dependent: :destroy

  validates :token_type, presence: true
  validates :value, presence: true
  validates :status, presence: true

  enum :status, {
    extracted: "extracted",
    designs_pending: "designs_pending",
    designs_ready: "designs_ready",
    in_production: "in_production",
    listed: "listed"
  }, default: :extracted

  scope :by_composite_score, -> { order(composite_score: :desc) }
  scope :ready_for_designs, -> { where(status: :extracted) }
end
