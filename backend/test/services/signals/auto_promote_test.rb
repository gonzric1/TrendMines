require "test_helper"

class Signals::AutoPromoteTest < ActiveSupport::TestCase
  test "promotes eligible signal to niche" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Test Fandom #{SecureRandom.hex(4)}", status: "watching",
      momentum_score: 8.0, first_seen: 5.days.ago, raw_data: {}
    )

    niche = Signals::AutoPromote.call(signal)

    assert_not_nil niche
    assert niche.persisted?
    assert_equal signal.topic, niche.name
    assert signal.reload.status_promoted?
  ensure
    signal&.reload&.niches&.destroy_all
    signal&.destroy
  end

  test "skips already promoted signals" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Already Promoted #{SecureRandom.hex(4)}", status: "promoted",
      momentum_score: 9.0, first_seen: 10.days.ago, raw_data: {}
    )

    result = Signals::AutoPromote.call(signal)
    assert_nil result
  ensure
    signal&.destroy
  end

  test "skips signals below momentum threshold" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Low Momentum #{SecureRandom.hex(4)}", status: "watching",
      momentum_score: 2.0, first_seen: 5.days.ago, raw_data: {}
    )

    result = Signals::AutoPromote.call(signal)
    assert_nil result
  ensure
    signal&.destroy
  end

  test "skips signals that are too young" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Too Young #{SecureRandom.hex(4)}", status: "watching",
      momentum_score: 9.0, first_seen: 1.hour.ago, raw_data: {}
    )

    result = Signals::AutoPromote.call(signal)
    assert_nil result
  ensure
    signal&.destroy
  end

  test "infers fandom community type from ao3_enriched" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Fandom Type #{SecureRandom.hex(4)}", status: "watching",
      momentum_score: 8.0, first_seen: 5.days.ago, raw_data: { "ao3_enriched" => true }
    )

    niche = Signals::AutoPromote.call(signal)
    assert_equal "fandom", niche.community_type
  ensure
    signal&.reload&.niches&.destroy_all
    signal&.destroy
  end

  test "infers reddit_community type from subreddit" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Reddit Type #{SecureRandom.hex(4)}", status: "watching",
      momentum_score: 8.0, first_seen: 5.days.ago, raw_data: { "subreddit" => "r/test" }
    )

    niche = Signals::AutoPromote.call(signal)
    assert_equal "reddit_community", niche.community_type
  ensure
    signal&.reload&.niches&.destroy_all
    signal&.destroy
  end
end
