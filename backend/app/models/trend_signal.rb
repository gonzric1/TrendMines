# Represents an early trend signal detected from various sources.
# Trend signals are monitored for momentum and promoted to niches when they
# show commercial potential.
#
# @attr [Integer] id Primary key
# @attr [String] source Source of the signal (e.g., 'twitter', 'reddit', 'google_trends')
# @attr [String] topic The trending topic or keyword
# @attr [Text] context Additional context about the signal
# @attr [Float] momentum_score Calculated momentum metric
# @attr [String] status Current monitoring status
# @attr [DateTime] detected_at When the signal was first detected
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class TrendSignal < ApplicationRecord
  has_many :signal_snapshots, dependent: :destroy
  has_many :niches, dependent: :destroy

  belongs_to :correlated_primary, class_name: "TrendSignal",
             foreign_key: "correlated_signal_id", optional: true
  has_many :correlated_signals, class_name: "TrendSignal",
           foreign_key: "correlated_signal_id"

  validates :source, presence: true
  validates :topic, presence: true
  validates :status, presence: true

  # Signal monitoring status
  # @note Uses prefix to avoid conflicts (status_new, status_watching, etc.)
  # @note Default status is :status_new
  enum :status, {
    status_new: "new",
    watching: "watching",
    promoted: "promoted",
    archived: "archived"
  }, prefix: true, default: :status_new

  # @!scope class
  # Returns signals sorted by momentum score in descending order
  # @return [ActiveRecord::Relation<TrendSignal>] Signals ordered by momentum
  scope :by_momentum, -> { order(momentum_score: :desc) }

  # @!scope class
  # Returns signals currently being monitored
  # @return [ActiveRecord::Relation<TrendSignal>] Signals with new or watching status
  scope :active, -> { where(status: [:new, :watching]) }

  # Returns all signals in this signal's correlation group (the primary + all linked signals).
  #
  # @return [Array<TrendSignal>]
  def correlation_group
    primary = correlated_signal_id.present? ? correlated_primary : self
    [primary] + primary.correlated_signals.where.not(id: primary.id).to_a
  end
end
