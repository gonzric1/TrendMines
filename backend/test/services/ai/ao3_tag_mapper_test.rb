require "test_helper"

class Ai::Ao3TagMapperTest < ActiveSupport::TestCase
  setup do
    @mock_scanner = Object.new
    @mock_scanner.define_singleton_method(:scan) { |topics:| [] }
  end

  test "returns topic as-is when direct match succeeds" do
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:scan) { |topics:|
      [{ source: "AO3", topic: topics.first, momentum_score: 5.0, raw_data: {} }]
    }

    Sources::FandomStats.stub(:new, mock_scanner) do
      result = Ai::Ao3TagMapper.call("Good Omens")
      assert_equal "Good Omens", result
    end
  end

  test "uses AI fallback when direct match fails" do
    call_count = 0
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:scan) { |topics:|
      call_count += 1
      if call_count == 1
        [] # First call (direct) fails
      else
        [{ source: "AO3", topic: topics.first, momentum_score: 5.0, raw_data: {} }] # AI suggestion succeeds
      end
    }

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |prompt:, system:, temperature:| "My Hero Academia" }

    Sources::FandomStats.stub(:new, mock_scanner) do
      Ai::OpenRouterClient.stub(:new, mock_client) do
        result = Ai::Ao3TagMapper.call("BNHA")
        assert_equal "My Hero Academia", result
      end
    end
  end

  test "returns nil when AI suggestion is not verified on AO3" do
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:scan) { |topics:| [] } # Always empty

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| "Nonexistent Fandom Tag" }

    Sources::FandomStats.stub(:new, mock_scanner) do
      Ai::OpenRouterClient.stub(:new, mock_client) do
        result = Ai::Ao3TagMapper.call("Something Random")
        assert_nil result
      end
    end
  end

  test "returns nil when AI is not configured" do
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:scan) { |topics:| [] }

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { false }

    Sources::FandomStats.stub(:new, mock_scanner) do
      Ai::OpenRouterClient.stub(:new, mock_client) do
        result = Ai::Ao3TagMapper.call("Unknown Topic")
        assert_nil result
      end
    end
  end

  test "returns nil when AI returns NONE" do
    mock_scanner = Object.new
    mock_scanner.define_singleton_method(:scan) { |topics:| [] }

    mock_client = Object.new
    mock_client.define_singleton_method(:configured?) { true }
    mock_client.define_singleton_method(:complete) { |**| "NONE" }

    Sources::FandomStats.stub(:new, mock_scanner) do
      Ai::OpenRouterClient.stub(:new, mock_client) do
        result = Ai::Ao3TagMapper.call("Gibberish")
        assert_nil result
      end
    end
  end
end
