require "test_helper"

class Sources::RedditTest < ActiveSupport::TestCase
  setup do
    @scanner = Sources::Reddit.new
  end

  test "credential_keys returns reddit client credentials" do
    assert_equal %w[reddit_client_id reddit_client_secret], @scanner.credential_keys
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

  test "scan processes subreddit data correctly" do
    mock_subreddits = [
      { "data" => { "display_name" => "TestSub", "subscribers" => 100000, "accounts_active" => 500 } }
    ]
    mock_rising = { "data" => { "children" => Array.new(5) { {} } } }
    mock_top = { "data" => { "children" => [{ "data" => { "score" => 5000 } }] } }

    @scanner.stub(:configured?, true) do
      @scanner.stub(:fetch_access_token, "fake-token") do
        @scanner.stub(:search_subreddits, mock_subreddits) do
          @scanner.stub(:fetch_rising, mock_rising) do
            @scanner.stub(:fetch_top_weekly, mock_top) do
              results = @scanner.scan(topics: ["gaming"])

              assert_equal 1, results.length
              result = results.first
              assert_equal "Reddit", result[:source]
              assert_equal "gaming", result[:topic]
              assert result[:momentum_score] > 0
              assert_equal "TestSub", result[:raw_data][:subreddit]
              assert_equal 100000, result[:raw_data][:subscribers]
            end
          end
        end
      end
    end
  end
end
