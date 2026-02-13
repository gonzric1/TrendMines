class MetricSnapshot < ApplicationRecord
  belongs_to :listing

  validates :captured_at, presence: true

  scope :recent, -> { order(captured_at: :desc) }
  scope :for_period, ->(start_date, end_date) { where(captured_at: start_date..end_date) }
end
