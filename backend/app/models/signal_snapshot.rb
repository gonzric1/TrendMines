# Represents a point-in-time snapshot of trend signal momentum.
# Snapshots are captured periodically to track momentum velocity
# and source metrics over time, powering sparkline charts in the Signal Radar.
#
# @attr [Integer] id Primary key
# @attr [Integer] trend_signal_id Foreign key to TrendSignal
# @attr [Float] momentum_score Momentum velocity at capture time
# @attr [Hash] source_metrics Platform-specific metrics at capture time
# @attr [DateTime] captured_at When this snapshot was captured
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class SignalSnapshot < ApplicationRecord
  belongs_to :trend_signal

  validates :captured_at, presence: true

  # @!scope class
  # Returns snapshots sorted by capture time in descending order
  # @return [ActiveRecord::Relation<SignalSnapshot>] Most recent snapshots first
  scope :recent, -> { order(captured_at: :desc) }

  # @!scope class
  # Returns snapshots captured within a specific time period
  # @param start_date [Date, DateTime] Start of the period
  # @param end_date [Date, DateTime] End of the period
  # @return [ActiveRecord::Relation<SignalSnapshot>] Snapshots within the date range
  scope :for_period, ->(start_date, end_date) { where(captured_at: start_date..end_date) }
end
