# Represents a cultural element extracted from a niche with design potential.
# Cultural tokens are key symbols, phrases, or concepts that resonate with
# a community and can be transformed into marketable designs.
#
# @attr [Integer] id Primary key
# @attr [Integer] niche_id Foreign key to Niche
# @attr [String] token_type Type of token (e.g., 'phrase', 'symbol', 'character', 'meme')
# @attr [String] value The actual content of the token
# @attr [Text] context Additional context explaining the token's cultural significance
# @attr [Float] composite_score Overall viability score for design conversion
# @attr [String] status Current production status
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class CulturalToken < ApplicationRecord
  belongs_to :niche
  has_many :designs, dependent: :destroy

  validates :token_type, presence: true
  validates :value, presence: true
  validates :status, presence: true

  # Production pipeline status for token-to-design conversion
  # @note Default status is :extracted
  enum :status, {
    extracted: "extracted",
    designs_pending: "designs_pending",
    designs_ready: "designs_ready",
    in_production: "in_production",
    listed: "listed"
  }, default: :extracted

  # @!scope class
  # Returns tokens sorted by composite score in descending order
  # @return [ActiveRecord::Relation<CulturalToken>] Tokens ordered by design viability
  scope :by_composite_score, -> { order(composite_score: :desc) }

  # @!scope class
  # Returns tokens ready for design generation
  # @return [ActiveRecord::Relation<CulturalToken>] Tokens with extracted status
  scope :ready_for_designs, -> { where(status: :extracted) }
end
