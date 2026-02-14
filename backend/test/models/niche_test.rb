require "test_helper"

class NicheTest < ActiveSupport::TestCase
  test "should create valid niche" do
    niche = Niche.new(
      trend_signal: trend_signals(:trending_anime),
      name: "Test Niche",
      status: "discovered"
    )
    assert niche.valid?
  end

  test "should require name" do
    niche = Niche.new(
      trend_signal: trend_signals(:trending_anime),
      status: "discovered"
    )
    assert_not niche.valid?
    assert_includes niche.errors[:name], "can't be blank"
  end

  test "should require status" do
    niche = Niche.new(
      trend_signal: trend_signals(:trending_anime),
      name: "Test",
      status: ""
    )
    assert_not niche.valid?
    assert_includes niche.errors[:status], "can't be blank"
  end

  test "should belong to trend signal" do
    niche = niches(:frieren_collectors)
    assert_respond_to niche, :trend_signal
    assert_kind_of TrendSignal, niche.trend_signal
  end

  test "should have many cultural tokens" do
    niche = niches(:frieren_collectors)
    assert_respond_to niche, :cultural_tokens
    assert_kind_of ActiveRecord::Associations::CollectionProxy, niche.cultural_tokens
  end

  test "should destroy associated cultural tokens when destroyed" do
    niche = niches(:archived_niche)
    token_count = niche.cultural_tokens.count
    assert token_count > 0, "Niche should have tokens for this test"

    assert_difference "CulturalToken.count", -token_count do
      niche.destroy
    end
  end

  test "should have default status of discovered" do
    niche = Niche.create!(
      trend_signal: trend_signals(:trending_anime),
      name: "Test"
    )
    assert_equal "discovered", niche.status
  end

  test "should allow valid status values" do
    niche = niches(:frieren_collectors)

    %w[discovered evaluating mining_tokens generating_designs active declining archived].each do |status|
      niche.status = status
      assert niche.valid?, "Status #{status} should be valid"
    end
  end

  test "by_demand_ratio scope should order by demand_supply_ratio descending" do
    niches_ordered = Niche.by_demand_ratio.to_a
    first_ratio = niches_ordered.first.demand_supply_ratio || 0
    last_ratio = niches_ordered.last.demand_supply_ratio || 0
    assert first_ratio >= last_ratio
  end

  test "active_pipeline scope should only return active pipeline statuses" do
    active_niches = Niche.active_pipeline
    statuses = active_niches.pluck(:status).uniq

    assert_includes statuses, "active"
    assert_not_includes statuses, "archived"
  end
end
