require "test_helper"

class Sources::TumblrTest < ActiveSupport::TestCase
  setup do
    @scanner = Sources::Tumblr.new
  end

  test "credential_keys returns tumblr consumer key" do
    assert_equal %w[tumblr_consumer_key], @scanner.credential_keys
  end

  test "configured? returns false when credentials are missing" do
    assert_not @scanner.configured?
  end

  test "scan returns empty when not configured" do
    results = @scanner.scan(topics: ["art"])
    assert_empty results
  end

  test "test_connection fails when not configured" do
    result = @scanner.test_connection
    assert_not result[:success]
    assert_includes result[:message], "not configured"
  end

  test "scan processes tagged posts correctly" do
    mock_posts = [
      { "note_count" => 150, "timestamp" => Time.current.to_i - 3600, "summary" => "amazing art" },
      { "note_count" => 300, "timestamp" => Time.current.to_i - 7200, "summary" => "i need this on a shirt" },
      { "note_count" => 50, "timestamp" => Time.current.to_i - 1800, "summary" => "cool post" }
    ]

    @scanner.stub(:configured?, true) do
      @scanner.stub(:credential, "fake-key") do
        @scanner.stub(:fetch_tagged_posts, mock_posts) do
          results = @scanner.scan(topics: ["fandom art"])

          assert_equal 1, results.length
          result = results.first
          assert_equal "Tumblr", result[:source]
          assert_equal "fandom art", result[:topic]
          assert result[:momentum_score] > 0
          assert_equal 3, result[:raw_data][:post_count]
          assert_equal 1, result[:raw_data][:wish_post_count]
        end
      end
    end
  end

  test "wish phrase detection works" do
    scanner = Sources::Tumblr.new
    post_with_wish = { "summary" => "omg i need this as a sticker", "note_count" => 10, "timestamp" => Time.current.to_i }
    post_without_wish = { "summary" => "nice artwork", "note_count" => 5, "timestamp" => Time.current.to_i }

    assert scanner.send(:contains_wish_phrase?, post_with_wish)
    assert_not scanner.send(:contains_wish_phrase?, post_without_wish)
  end
end
