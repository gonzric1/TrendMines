require "test_helper"

class Niches::CalculateScorecardTest < ActiveSupport::TestCase
  test "computes weighted composite score" do
    niche = niches(:frieren_collectors)
    result = Niches::CalculateScorecard.new(niche).call

    assert result[:composite_score].is_a?(Float)
    assert result[:composite_score] > 0
    assert result[:components].key?("momentum")
    assert result[:components].key?("demand_supply")
    assert result[:components].key?("cultural_depth")
    assert result[:components].key?("visual_potential")
    assert result[:components].key?("uniqueness")
  end

  test "uses settings for weights" do
    niche = niches(:frieren_collectors)
    result = Niches::CalculateScorecard.new(niche).call

    # momentum_weight fixture is 3, demand_supply_weight fixture is 5
    assert_equal 3, result[:weights]["momentum_weight"]
    assert_equal 5, result[:weights]["demand_supply_weight"]
  end

  test "handles niche with no cultural tokens" do
    # archived_niche has a stranger_things_token, so use a niche we create without tokens
    signal = trend_signals(:new_signal)
    niche = Niche.create!(
      trend_signal: signal,
      name: "Empty Niche",
      status: "discovered"
    )

    result = Niches::CalculateScorecard.new(niche).call

    assert_equal 0.0, result[:components]["cultural_depth"]
    assert_equal 0.0, result[:components]["visual_potential"]
    assert_equal 0.0, result[:components]["uniqueness"]
    assert result[:composite_score] >= 0
  end

  test "returns viable flag based on threshold" do
    niche = niches(:frieren_collectors)
    result = Niches::CalculateScorecard.new(niche).call

    # viability_threshold fixture is 0.6
    assert_equal result[:composite_score] >= 0.6, result[:viable]
  end

  test "normalizes component scores between 0 and 1" do
    niche = niches(:frieren_collectors)
    result = Niches::CalculateScorecard.new(niche).call

    result[:components].each do |_key, value|
      assert value >= 0.0, "Component score should be >= 0"
      assert value <= 1.0, "Component score should be <= 1"
    end
  end
end
