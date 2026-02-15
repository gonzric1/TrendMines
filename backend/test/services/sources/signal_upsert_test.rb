require "test_helper"

class Sources::SignalUpsertTest < ActiveSupport::TestCase
  test "creates new TrendSignal from results" do
    results = [
      {
        source: "TestSource",
        topic: "New Topic #{SecureRandom.hex(4)}",
        description: "Test description",
        momentum_score: 7.5,
        raw_data: { test_key: "test_value" }
      }
    ]

    assert_difference "TrendSignal.count", 1 do
      assert_difference "SignalSnapshot.count", 1 do
        count = Sources::SignalUpsert.call(results)
        assert_equal 1, count
      end
    end

    signal = TrendSignal.last
    assert_equal "TestSource", signal.source
    assert_equal 7.5, signal.momentum_score
    assert_equal "test_value", signal.raw_data["test_key"]
    assert_not_nil signal.first_seen
    assert_not_nil signal.last_updated
  end

  test "updates existing TrendSignal on same source+topic" do
    signal = TrendSignal.create!(
      source: "AO3",
      topic: "Existing Topic",
      description: "Old description",
      momentum_score: 5.0,
      status: "watching",
      raw_data: { old_key: "old_value" }
    )

    results = [
      {
        source: "AO3",
        topic: "Existing Topic",
        description: "Updated description",
        momentum_score: 8.0,
        raw_data: { new_key: "new_value" }
      }
    ]

    assert_no_difference "TrendSignal.count" do
      Sources::SignalUpsert.call(results)
    end

    signal.reload
    assert_equal 8.0, signal.momentum_score
    assert_equal "Updated description", signal.description
    # Merges raw_data
    assert_equal "old_value", signal.raw_data["old_key"]
    assert_equal "new_value", signal.raw_data["new_key"]
  end

  test "creates SignalSnapshot for each upsert" do
    results = [
      {
        source: "TestSource",
        topic: "Snapshot Topic #{SecureRandom.hex(4)}",
        description: "Test",
        momentum_score: 6.0,
        raw_data: {}
      }
    ]

    Sources::SignalUpsert.call(results)

    snapshot = SignalSnapshot.last
    assert_not_nil snapshot
    assert_equal 6.0, snapshot.momentum_score
    assert_not_nil snapshot.captured_at
  end

  test "returns 0 for blank results" do
    assert_equal 0, Sources::SignalUpsert.call(nil)
    assert_equal 0, Sources::SignalUpsert.call([])
  end

  test "handles errors gracefully per result" do
    results = [
      { source: nil, topic: nil, description: "Bad", momentum_score: 1.0, raw_data: {} },
      {
        source: "Good",
        topic: "Valid Topic #{SecureRandom.hex(4)}",
        description: "Good result",
        momentum_score: 5.0,
        raw_data: {}
      }
    ]

    # Should still process the valid result
    count = Sources::SignalUpsert.call(results)
    assert_equal 1, count
  end
end
