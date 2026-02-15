# Stores application configuration values for scanning, scoring, alerts,
# templates, and integrations. API keys are managed via Rails credentials,
# not this table.
#
# @attr [Integer] id Primary key
# @attr [String] key Unique dot-notation key (e.g., "scanning.ao3_frequency")
# @attr [Object] value JSON value (numbers, strings, objects)
# @attr [String] category Grouping category for settings
# @attr [String] description Human-readable explanation of the setting
# @attr [DateTime] created_at Record creation timestamp
# @attr [DateTime] updated_at Record update timestamp
class Setting < ApplicationRecord
  CATEGORIES = %w[scanning scoring alerts templates integrations api_keys].freeze

  validates :key, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }
  validate :validate_value_by_category

  scope :by_category, ->(cat) { where(category: cat) }

  # Returns settings grouped by category as a hash.
  #
  # @return [Hash{String => Array<Setting>}]
  def self.grouped_by_category
    all.group_by(&:category)
  end

  private

  # Validates setting values based on their category.
  # - scanning: must be positive integers (hours)
  # - scoring weights: must be integers 1-10
  # - scoring threshold: must be float 0-1
  # - scoring _min: must be positive numbers
  # - alerts: must be numeric, thresholds 0-1 for ratios, positive for counts
  def validate_value_by_category
    return if value.nil?

    case category
    when "api_keys"
      # Encrypted strings — skip validation
      return
    when "scanning"
      return if key&.end_with?("_last_scan") # ISO8601 timestamps
      validate_positive_integer
    when "scoring"
      if key&.end_with?("_threshold")
        validate_ratio
      elsif key&.end_with?("_min")
        validate_positive_number
      else
        validate_weight
      end
    when "alerts"
      if key&.end_with?("_ratio") || key&.include?("threshold")
        validate_ratio
      else
        validate_positive_number
      end
    end
  end

  def validate_positive_integer
    unless value.is_a?(Integer) && value > 0
      errors.add(:value, "must be a positive integer")
    end
  end

  def validate_weight
    unless value.is_a?(Integer) && value.between?(1, 10)
      errors.add(:value, "must be an integer between 1 and 10")
    end
  end

  def validate_ratio
    unless value.is_a?(Numeric) && value.between?(0, 1)
      errors.add(:value, "must be a number between 0 and 1")
    end
  end

  def validate_positive_number
    unless value.is_a?(Numeric) && value > 0
      errors.add(:value, "must be a positive number")
    end
  end
end
