class PrinterAssignment < ApplicationRecord
  belongs_to :product

  validates :printer_name, presence: true
  validates :status, presence: true

  enum :status, {
    active: "active",
    paused: "paused",
    completed: "completed"
  }, default: :active

  scope :active, -> { where(status: :active) }
end
