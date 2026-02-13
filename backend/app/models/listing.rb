class Listing < ApplicationRecord
  belongs_to :product
  has_many :metric_snapshots, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true

  enum :status, {
    draft: "draft",
    active: "active",
    sold_out: "sold_out",
    paused: "paused"
  }, default: :draft

  scope :active, -> { where(status: :active) }
  scope :with_metrics, -> { includes(:metric_snapshots).where.not(metric_snapshots: { id: nil }) }
end
