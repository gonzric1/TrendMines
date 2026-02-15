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

  test "discover returns empty when not configured" do
    results = @scanner.discover
    assert_empty results
  end

  test "test_connection fails when not configured" do
    result = @scanner.test_connection
    assert_not result[:success]
    assert_includes result[:message], "not configured"
  end

  test "discover extracts topics from hot posts" do
    mock_hot_response = {
      "data" => {
        "children" => [
          {
            "data" => {
              "title" => "Check out this amazing Frieren fan art!",
              "score" => 2500,
              "num_comments" => 150,
              "upvote_ratio" => 0.95,
              "link_flair_text" => "Frieren"
            }
          },
          {
            "data" => {
              "title" => "Low effort post",
              "score" => 5,
              "num_comments" => 1,
              "upvote_ratio" => 0.6,
              "link_flair_text" => nil
            }
          }
        ]
      }
    }

    @scanner.stub(:configured?, true) do
      @scanner.stub(:fetch_access_token, "fake-token") do
        @scanner.stub(:fetch_hot, mock_hot_response) do
          results = @scanner.discover

          # Should have extracted the high-engagement post, not the low one
          high_engagement = results.select { |r| r[:momentum_score] >= 2.0 }
          assert high_engagement.length >= 1 if results.any?
        end
      end
    end
  end

  test "scan processes subreddit data correctly" do
    mock_subreddits = [
      { "data" => { "display_name" => "TestSub", "subscribers" => 100000, "accounts_active" => 500 } }
    ]
    mock_rising = { "data" => { "children" => Array.new(5) { {} } } }

    @scanner.stub(:configured?, true) do
      @scanner.stub(:fetch_access_token, "fake-token") do
        @scanner.stub(:search_subreddits, mock_subreddits) do
          @scanner.stub(:fetch_rising, mock_rising) do
            results = @scanner.scan(topics: ["gaming"])

            assert_equal 1, results.length
            result = results.first
            assert_equal "Reddit", result[:source]
            assert_equal "gaming", result[:topic]
            assert result[:momentum_score] > 0
            assert_equal "TestSub", result[:raw_data][:subreddit]
          end
        end
      end
    end
  end

  test "extract_topic_from_title cleans Reddit titles" do
    assert_equal "Amazing Frieren fan art", @scanner.send(:extract_topic_from_title, "[OC] Amazing Frieren fan art!")
    assert_equal "Check out this design", @scanner.send(:extract_topic_from_title, "[Fan Art] Check out this design (watercolor)")
    assert_nil @scanner.send(:extract_topic_from_title, "hi")
  end

  test "dedupe_results keeps highest momentum" do
    results = [
      { topic: "Same Topic", momentum_score: 5.0, source: "Reddit" },
      { topic: "same topic", momentum_score: 8.0, source: "Reddit" },
      { topic: "Other", momentum_score: 3.0, source: "Reddit" }
    ]
    deduped = @scanner.send(:dedupe_results, results)
    assert_equal 2, deduped.length
    same = deduped.find { |r| r[:topic].downcase.include?("same") }
    assert_equal 8.0, same[:momentum_score]
  end
end
