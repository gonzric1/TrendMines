require "test_helper"

class Signals::PromoteToNicheTest < ActiveSupport::TestCase
  test "creates niche from signal with default params" do
    signal = trend_signals(:new_signal)

    niche = Signals::PromoteToNiche.new(signal).call

    assert niche.persisted?
    assert_equal signal.topic, niche.name
    assert_equal signal.description, niche.description
    assert_equal "general", niche.community_type
    assert_equal "discovered", niche.status
    assert_not_nil niche.discovered_at
    assert_equal signal, niche.trend_signal
  end

  test "updates signal status to promoted" do
    signal = trend_signals(:new_signal)

    Signals::PromoteToNiche.new(signal).call

    assert signal.reload.status_promoted?
  end

  test "uses custom params when provided" do
    signal = trend_signals(:new_signal)
    params = {
      name: "Custom Niche Name",
      description: "Custom description",
      community_type: "gaming"
    }

    niche = Signals::PromoteToNiche.new(signal, params).call

    assert_equal "Custom Niche Name", niche.name
    assert_equal "Custom description", niche.description
    assert_equal "gaming", niche.community_type
  end

  test "rolls back on failure" do
    signal = trend_signals(:new_signal)
    # Force a validation failure by passing a name that's blank (Niche validates presence of name)
    params = { name: "" }

    assert_raises(ActiveRecord::RecordInvalid) do
      Signals::PromoteToNiche.new(signal, params).call
    end

    # Signal status should not have changed
    assert signal.reload.status_status_new?
  end
end
