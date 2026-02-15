require "test_helper"

class Sources::FandomStatsTest < ActiveSupport::TestCase
  setup do
    @scanner = Sources::FandomStats.new
  end

  test "configured? is always true" do
    assert @scanner.configured?
  end

  test "credential_keys is empty" do
    assert_empty @scanner.credential_keys
  end

  test "scan returns results from mocked API" do
    mock_response = {
      "works_count" => 45000,
      "recent_works_count" => 500,
      "bookmarks_count" => 12000,
      "tag_id" => "Good Omens"
    }

    @scanner.stub(:fetch_tag_stats, mock_response) do
      results = @scanner.scan(topics: ["Good Omens"])

      assert_equal 1, results.length
      result = results.first
      assert_equal "AO3", result[:source]
      assert_equal "Good Omens", result[:topic]
      assert result[:momentum_score] > 0
      assert_equal 45000, result[:raw_data][:ao3_works]
    end
  end

  test "scan skips topics with nil API response" do
    @scanner.stub(:fetch_tag_stats, nil) do
      results = @scanner.scan(topics: ["nonexistent"])
      assert_empty results
    end
  end

  test "scan handles multiple topics" do
    call_count = 0
    mock = lambda do |_tag|
      call_count += 1
      { "works_count" => 1000 * call_count, "recent_works_count" => 50 }
    end

    @scanner.stub(:fetch_tag_stats, mock) do
      results = @scanner.scan(topics: ["Topic A", "Topic B"])
      assert_equal 2, results.length
    end
  end

  test "test_connection returns success on valid response" do
    mock_response = { "works_count" => 10000, "tag_id" => "Sherlock Holmes" }

    @scanner.stub(:fetch_tag_stats, mock_response) do
      result = @scanner.test_connection
      assert result[:success]
      assert_includes result[:message], "fandomstats.org"
    end
  end

  test "test_connection returns failure on nil response" do
    @scanner.stub(:fetch_tag_stats, nil) do
      result = @scanner.test_connection
      assert_not result[:success]
    end
  end
end
