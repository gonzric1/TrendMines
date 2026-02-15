class WebhookDelivery < ApplicationRecord
  enum :status, {
    pending: "pending",
    delivered: "delivered",
    failed: "failed"
  }, default: :pending

  validates :event_type, presence: true
  validates :payload, presence: true
  validates :url, presence: true
  validates :status, presence: true

  scope :pending, -> { where(status: :pending) }
  scope :failed, -> { where(status: :failed) }
  scope :recent, -> { order(created_at: :desc) }
end
