class Product < ApplicationRecord
  belongs_to :design
  has_many :listings, dependent: :destroy
  has_many :printer_assignments, dependent: :destroy

  validates :product_type, presence: true
  validates :name, presence: true
  validates :status, presence: true

  enum :status, {
    prototype: "prototype",
    listed: "listed",
    scaling: "scaling",
    declining: "declining",
    retired: "retired"
  }, default: :prototype

  scope :active, -> { where(status: [:listed, :scaling]) }
end
