require "test_helper"

class Signals::CorrelateSourcesTest < ActiveSupport::TestCase
  test "correlates signals with normalized string match" do
    signal_a = TrendSignal.create!(
      source: "Reddit", topic: "Good Omens", status: "watching",
      momentum_score: 7.0, first_seen: 3.days.ago, raw_data: {}
    )
    signal_b = TrendSignal.create!(
      source: "Tumblr", topic: "good omens", status: "watching",
      momentum_score: 6.5, first_seen: 1.day.ago, raw_data: {}
    )

    result = Signals::CorrelateSources.call(signal_b)

    assert_not_nil result
    signal_b.reload
    assert_equal signal_a.id, signal_b.correlated_signal_id
  ensure
    signal_b&.update_column(:correlated_signal_id, nil)
    signal_b&.destroy
    signal_a&.destroy
  end

  test "older signal becomes primary" do
    signal_old = TrendSignal.create!(
      source: "Reddit", topic: "The Witcher", status: "watching",
      momentum_score: 7.0, first_seen: 5.days.ago, raw_data: {}
    )
    signal_new = TrendSignal.create!(
      source: "Google Trends", topic: "the witcher", status: "new",
      momentum_score: 6.0, first_seen: 1.day.ago, raw_data: {}
    )

    Signals::CorrelateSources.call(signal_new)

    signal_new.reload
    assert_equal signal_old.id, signal_new.correlated_signal_id
    assert_nil signal_old.reload.correlated_signal_id
  ensure
    signal_new&.update_column(:correlated_signal_id, nil)
    signal_new&.destroy
    signal_old&.destroy
  end

  test "skips already-correlated signals" do
    signal = trend_signals(:trending_anime)
    # Use a real signal ID to satisfy FK constraint
    other = trend_signals(:new_signal)
    signal.update_column(:correlated_signal_id, other.id)

    result = Signals::CorrelateSources.call(signal)
    assert_nil result
  ensure
    signal.update_column(:correlated_signal_id, nil)
  end

  test "returns nil when no candidates exist" do
    signal = TrendSignal.create!(
      source: "Reddit", topic: "Unique Topic #{SecureRandom.hex(8)}", status: "new",
      momentum_score: 5.0, first_seen: 1.day.ago, raw_data: {}
    )

    result = Signals::CorrelateSources.call(signal)
    assert_nil result
  ensure
    signal&.destroy
  end

  test "uses AI fallback when normalized match fails" do
    signal_a = TrendSignal.create!(
      source: "Reddit", topic: "BNHA", status: "watching",
      momentum_score: 7.0, first_seen: 3.days.ago, raw_data: {}
    )
    signal_b = TrendSignal.create!(
      source: "AO3", topic: "My Hero Academia", status: "watching",
      momentum_score: 8.0, first_seen: 5.days.ago, raw_data: {}
    )

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |prompt:, **| signal_b.id.to_s }

    Ai::OpenRouterClient.stub(:new, mock_client) do
      result = Signals::CorrelateSources.call(signal_a)
      assert_not_nil result

      signal_a.reload
      assert_equal signal_b.id, signal_a.correlated_signal_id
    end
  ensure
    signal_a&.update_column(:correlated_signal_id, nil)
    signal_a&.destroy
    signal_b&.destroy
  end
end
