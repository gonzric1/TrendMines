# Represents a design concept generated from a cultural token.
# Designs are AI-generated artwork that go through review and approval
# before being converted into physical products.
#
# @attr [Integer] id Primary key
# @attr [Integer] cultural_token_id Foreign key to CulturalToken
# @attr [String] design_type Type of design (e.g., 'graphic', 'pattern', 'illustration')
# @attr [String] prompt AI generation prompt used
# @attr [String] image_url URL to the generated design image
# @attr [Text] design_notes Internal notes about the design
# @attr [String] status Current review status
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class Design < ApplicationRecord
  belongs_to :cultural_token
  has_many :products, dependent: :nullify

  validates :design_type, presence: true
  validates :status, presence: true

  # Design review workflow status
  # @note Default status is :pending_review
  enum :status, {
    pending_review: "pending_review",
    approved: "approved",
    rejected: "rejected",
    needs_revision: "needs_revision"
  }, default: :pending_review

  # @!scope class
  # Returns designs awaiting review
  # @return [ActiveRecord::Relation<Design>] Designs with pending_review status
  scope :pending, -> { where(status: :pending_review) }

  # @!scope class
  # Returns approved designs ready for product creation
  # @return [ActiveRecord::Relation<Design>] Designs with approved status
  scope :approved, -> { where(status: :approved) }
end
