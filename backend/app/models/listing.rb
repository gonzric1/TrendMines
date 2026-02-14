# Represents a marketplace listing for a product.
# Listings track the product's presence on platforms like Etsy, including
# its title, description, pricing, and current status.
#
# @attr [Integer] id Primary key
# @attr [Integer] product_id Foreign key to Product
# @attr [String] platform Marketplace platform (e.g., 'etsy', 'amazon')
# @attr [String] listing_id External platform's listing identifier
# @attr [String] title Public listing title
# @attr [Text] description Public listing description
# @attr [Float] price Current listing price in USD
# @attr [String] status Current listing status
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class Listing < ApplicationRecord
  belongs_to :product
  has_many :metric_snapshots, dependent: :destroy

  validates :title, presence: true
  validates :status, presence: true

  # Marketplace listing status
  # @note Default status is :draft
  enum :status, {
    draft: "draft",
    active: "active",
    sold_out: "sold_out",
    paused: "paused"
  }, default: :draft

  # @!scope class
  # Returns listings currently active on the marketplace
  # @return [ActiveRecord::Relation<Listing>] Listings with active status
  scope :active, -> { where(status: :active) }

  # @!scope class
  # Returns listings that have performance metrics
  # @return [ActiveRecord::Relation<Listing>] Listings with associated metric snapshots
  scope :with_metrics, -> { includes(:metric_snapshots).where.not(metric_snapshots: { id: nil }) }
end
