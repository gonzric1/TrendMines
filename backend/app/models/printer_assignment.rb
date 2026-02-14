# Represents the assignment of a product to a specific 3D printer.
# Tracks which printers are producing which products and their current
# production status for capacity planning and workflow management.
#
# @attr [Integer] id Primary key
# @attr [Integer] product_id Foreign key to Product
# @attr [String] printer_name Name/identifier of the 3D printer
# @attr [Integer] units_remaining Number of units left to print in this assignment
# @attr [String] status Current production status
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class PrinterAssignment < ApplicationRecord
  belongs_to :product

  validates :printer_name, presence: true
  validates :status, presence: true

  # Production status for this printer assignment
  # @note Default status is :active
  enum :status, {
    active: "active",
    paused: "paused",
    completed: "completed"
  }, default: :active

  # @!scope class
  # Returns assignments currently in production
  # @return [ActiveRecord::Relation<PrinterAssignment>] Assignments with active status
  scope :active, -> { where(status: :active) }
end
