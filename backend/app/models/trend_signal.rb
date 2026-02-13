class TrendSignal < ApplicationRecord
  has_many :niches, dependent: :destroy

  validates :source, presence: true
  validates :topic, presence: true
  validates :status, presence: true

  enum :status, {
    status_new: "new",
    watching: "watching",
    promoted: "promoted",
    archived: "archived"
  }, prefix: true, default: :status_new

  scope :by_momentum, -> { order(momentum_score: :desc) }
  scope :active, -> { where(status: [:new, :watching]) }
end
