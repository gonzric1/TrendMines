class Design < ApplicationRecord
  belongs_to :cultural_token
  has_many :products, dependent: :nullify

  validates :design_type, presence: true
  validates :status, presence: true

  enum :status, {
    pending_review: "pending_review",
    approved: "approved",
    rejected: "rejected",
    needs_revision: "needs_revision"
  }, default: :pending_review

  scope :pending, -> { where(status: :pending_review) }
  scope :approved, -> { where(status: :approved) }
end
