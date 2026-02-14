# Represents a physical print-on-demand product derived from a design.
# Products go through a lifecycle from prototype to listing on marketplaces,
# tracking production costs, pricing, and manufacturing assignments.
#
# @attr [Integer] id Primary key
# @attr [Integer] design_id Foreign key to Design
# @attr [String] product_type Type of product (e.g., 't_shirt', 'mug', 'poster')
# @attr [String] name Display name for the product
# @attr [Float] unit_cost Cost per unit in USD
# @attr [Float] target_price Desired selling price in USD
# @attr [Float] margin_pct Profit margin percentage
# @attr [Integer] print_time_minutes Time required to produce one unit
# @attr [Integer] units_per_batch Number of units producible in one batch
# @attr [String] stl_file_url URL to STL file for 3D printing
# @attr [String] status Current lifecycle status
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class Product < ApplicationRecord
  belongs_to :design
  has_many :listings, dependent: :destroy
  has_many :printer_assignments, dependent: :destroy

  validates :product_type, presence: true
  validates :name, presence: true
  validates :status, presence: true

  # Product lifecycle status
  # @note Default status is :prototype
  enum :status, {
    prototype: "prototype",
    listed: "listed",
    scaling: "scaling",
    declining: "declining",
    retired: "retired"
  }, default: :prototype

  # @!scope class
  # Returns products that are currently active in the marketplace
  # @return [ActiveRecord::Relation<Product>] Products with listed or scaling status
  scope :active, -> { where(status: [:listed, :scaling]) }
end
