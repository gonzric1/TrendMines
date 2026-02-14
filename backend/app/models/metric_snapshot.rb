# Represents a point-in-time snapshot of listing performance metrics.
# Snapshots are captured periodically to track views, favorites, sales,
# and other marketplace performance indicators over time.
#
# @attr [Integer] id Primary key
# @attr [Integer] listing_id Foreign key to Listing
# @attr [Integer] views Number of listing views
# @attr [Integer] favorites Number of favorites/hearts
# @attr [Integer] sales Number of sales
# @attr [Float] revenue Total revenue in USD
# @attr [DateTime] captured_at When this snapshot was captured
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class MetricSnapshot < ApplicationRecord
  belongs_to :listing

  validates :captured_at, presence: true

  # @!scope class
  # Returns snapshots sorted by capture time in descending order
  # @return [ActiveRecord::Relation<MetricSnapshot>] Most recent snapshots first
  scope :recent, -> { order(captured_at: :desc) }

  # @!scope class
  # Returns snapshots captured within a specific time period
  # @param start_date [Date, DateTime] Start of the period
  # @param end_date [Date, DateTime] End of the period
  # @return [ActiveRecord::Relation<MetricSnapshot>] Snapshots within the date range
  scope :for_period, ->(start_date, end_date) { where(captured_at: start_date..end_date) }
end
