require "test_helper"

class Sources::GoogleTrendsTest < ActiveSupport::TestCase
  setup do
    @scanner = Sources::GoogleTrends.new
  end

  test "credential_keys returns serpapi key" do
    assert_equal %w[serpapi_api_key], @scanner.credential_keys
  end

  test "configured? returns false when credentials are missing" do
    assert_not @scanner.configured?
  end

  test "scan returns empty when not configured" do
    results = @scanner.scan(topics: ["test"])
    assert_empty results
  end

  test "test_connection fails when not configured" do
    result = @scanner.test_connection
    assert_not result[:success]
    assert_includes result[:message], "not configured"
  end

  test "scan processes trend data correctly" do
    mock_data = {
      "interest_over_time" => {
        "timeline_data" => [
          { "values" => [{ "extracted_value" => 30 }] },
          { "values" => [{ "extracted_value" => 50 }] },
          { "values" => [{ "extracted_value" => 75 }] },
          { "values" => [{ "extracted_value" => 90 }] },
          { "values" => [{ "extracted_value" => 100 }] },
          { "values" => [{ "extracted_value" => 85 }] }
        ]
      },
      "related_queries" => {
        "rising" => [
          { "query" => "new trend", "extracted_value" => "Breakout" },
          { "query" => "growing topic", "extracted_value" => 450 }
        ],
        "top" => [
          { "query" => "main query", "extracted_value" => 100 }
        ]
      }
    }

    @scanner.stub(:configured?, true) do
      @scanner.stub(:credential, "fake-key") do
        @scanner.stub(:fetch_trends, mock_data) do
          results = @scanner.scan(topics: ["trending topic"])

          assert_equal 1, results.length
          result = results.first
          assert_equal "Google Trends", result[:source]
          assert_equal "trending topic", result[:topic]
          assert result[:momentum_score] > 0
          assert_equal 1, result[:raw_data][:breakout_count]
          assert result[:raw_data][:interest_over_time][:average] > 0
        end
      end
    end
  end

  test "extract_interest_over_time handles empty data" do
    result = @scanner.send(:extract_interest_over_time, {})
    assert_equal 0, result[:average]
    assert_equal "flat", result[:trend]
  end

  test "extract_related_queries identifies breakout terms" do
    data = {
      "related_queries" => {
        "rising" => [
          { "query" => "breakout term", "extracted_value" => "Breakout" },
          { "query" => "normal rise", "extracted_value" => 200 }
        ],
        "top" => []
      }
    }

    queries = @scanner.send(:extract_related_queries, data)
    breakouts = queries.select { |q| q[:type] == "breakout" }
    assert_equal 1, breakouts.length
    assert_equal "breakout term", breakouts.first[:query]
  end
end
