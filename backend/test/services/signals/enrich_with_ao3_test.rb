require "test_helper"

class Signals::EnrichWithAo3Test < ActiveSupport::TestCase
  test "enriches signal with AO3 data" do
    signal = trend_signals(:new_signal)
    signal.update!(raw_data: {})

    mock_result = {
      source: "AO3",
      topic: "Baldur's Gate 3",
      momentum_score: 7.0,
      raw_data: {
        ao3_works: 15000,
        shipping_ratio: 0.75,
        top_relationships: [{ name: "Astarion/Tav", count: 5000 }],
        top_freeform_tags: [{ tag: "Fluff", count: 3000 }]
      }
    }

    Ai::Ao3TagMapper.stub(:call, "Baldur's Gate") do
      mock_scanner = Object.new
      mock_scanner.define_singleton_method(:scan) { |topics:| [mock_result] }

      Sources::FandomStats.stub(:new, mock_scanner) do
        result = Signals::EnrichWithAo3.call(signal)
        assert result

        signal.reload
        assert signal.raw_data["ao3_enriched"]
        assert_equal 15000, signal.raw_data["ao3_works"]
        assert_equal 0.75, signal.raw_data["ao3_shipping_ratio"]
      end
    end
  end

  test "skips if already enriched" do
    signal = trend_signals(:new_signal)
    signal.update!(raw_data: { "ao3_enriched" => true })

    result = Signals::EnrichWithAo3.call(signal)
    assert_not result
  end

  test "returns false when no AO3 tag mapping found" do
    signal = trend_signals(:new_signal)
    signal.update!(raw_data: {})

    Ai::Ao3TagMapper.stub(:call, nil) do
      result = Signals::EnrichWithAo3.call(signal)
      assert_not result
    end
  end

  test "preserves existing raw_data when merging" do
    signal = trend_signals(:new_signal)
    signal.update!(raw_data: { "existing_key" => "keep_me" })

    mock_result = {
      source: "AO3", topic: "test", momentum_score: 5.0,
      raw_data: { ao3_works: 100, shipping_ratio: 0.5, top_relationships: [], top_freeform_tags: [] }
    }

    Ai::Ao3TagMapper.stub(:call, "test") do
      mock_scanner = Object.new
      mock_scanner.define_singleton_method(:scan) { |topics:| [mock_result] }

      Sources::FandomStats.stub(:new, mock_scanner) do
        Signals::EnrichWithAo3.call(signal)
        signal.reload
        assert_equal "keep_me", signal.raw_data["existing_key"]
        assert signal.raw_data["ao3_enriched"]
      end
    end
  end
end
