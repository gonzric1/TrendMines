require "test_helper"

class TrendSignalTest < ActiveSupport::TestCase
  test "should create valid trend signal" do
    signal = TrendSignal.new(
      source: "twitter",
      topic: "Test Topic",
      status: "new"
    )
    assert signal.valid?
  end

  test "should require source" do
    signal = TrendSignal.new(topic: "Test", status: "new")
    assert_not signal.valid?
    assert_includes signal.errors[:source], "can't be blank"
  end

  test "should require topic" do
    signal = TrendSignal.new(source: "twitter", status: "new")
    assert_not signal.valid?
    assert_includes signal.errors[:topic], "can't be blank"
  end

  test "should require status" do
    signal = TrendSignal.new(source: "twitter", topic: "Test", status: "")
    assert_not signal.valid?
    assert_includes signal.errors[:status], "can't be blank"
  end

  test "should have default status of status_new" do
    signal = TrendSignal.create!(source: "twitter", topic: "Test")
    assert_equal "status_new", signal.status
  end

  test "should allow valid status values" do
    signal = trend_signals(:trending_anime)

    signal.status = :watching
    assert signal.valid?

    signal.status = :promoted
    assert signal.valid?

    signal.status = :archived
    assert signal.valid?
  end

  test "should have many niches" do
    signal = trend_signals(:trending_anime)
    assert_respond_to signal, :niches
    assert_kind_of ActiveRecord::Associations::CollectionProxy, signal.niches
  end

  test "should destroy associated niches when destroyed" do
    signal = trend_signals(:archived_show)
    niche_count = signal.niches.count
    assert niche_count > 0, "Signal should have niches for this test"

    assert_difference "Niche.count", -niche_count do
      signal.destroy
    end
  end

  test "by_momentum scope should order by momentum_score descending" do
    signals = TrendSignal.by_momentum.to_a
    assert signals.first.momentum_score >= signals.last.momentum_score
  end

  test "active scope should only return new and watching signals" do
    active_signals = TrendSignal.active.pluck(:status).uniq.sort
    expected = ["status_new", "watching"].sort
    assert_equal expected, active_signals
    assert_not_includes active_signals, "archived"
  end
end
