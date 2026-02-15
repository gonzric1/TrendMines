require "test_helper"

class Sources::FandomStatsTest < ActiveSupport::TestCase
  setup do
    @scanner = Sources::FandomStats.new
    # Real API response format from fandomstats.org
    @mock_response = {
      "numworks" => 0,
      "stats" => {
        "rating" => { "General Audiences" => 36374, "Teen And Up Audiences" => 33073 },
        "category" => { "Gen" => 26810, "F/F" => 2050, "F/M" => 18631, "M/M" => 68920, "Multi" => 3156 },
        "fandom" => {
          "Sherlock (BBC TV 2010)" => 92775,
          "Sherlock Holmes & Related Fandoms" => 27378,
          "Sherlock Holmes - Arthur Conan Doyle" => 8059
        },
        "character" => { "Sherlock Holmes" => 106828, "John Watson" => 85907 },
        "relationship" => {
          "Sherlock Holmes/John Watson" => 57746,
          "Sherlock Holmes & John Watson" => 19405
        },
        "freeform" => { "Fluff" => 16663, "Angst" => 13195, "Hurt/Comfort" => 7520, "Romance" => 5702, "Humor" => 5136 }
      }
    }
  end

  test "configured? is always true" do
    assert @scanner.configured?
  end

  test "credential_keys is empty" do
    assert_empty @scanner.credential_keys
  end

  test "scan returns results from mocked API response" do
    @scanner.stub(:fetch_tag_stats, @mock_response) do
      results = @scanner.scan(topics: ["Sherlock Holmes"])

      assert_equal 1, results.length
      result = results.first
      assert_equal "AO3", result[:source]
      assert_equal "Sherlock Holmes", result[:topic]
      assert result[:momentum_score] > 0
      # Works count from fandom breakdown since numworks=0
      assert result[:raw_data][:ao3_works] > 0
      assert_equal 3, result[:raw_data][:fandom_count]
      assert result[:raw_data][:shipping_ratio] > 0
      assert result[:raw_data][:top_relationships].length > 0
      assert result[:raw_data][:top_freeform_tags].length > 0
    end
  end

  test "scan skips topics with nil API response" do
    @scanner.stub(:fetch_tag_stats, nil) do
      results = @scanner.scan(topics: ["nonexistent"])
      assert_empty results
    end
  end

  test "scan skips API error responses" do
    error_response = { "message" => "Internal Server Error" }
    @scanner.stub(:fetch_tag_stats, error_response) do
      results = @scanner.scan(topics: ["bad tag"])
      assert_empty results
    end
  end

  test "scan handles multiple topics" do
    call_count = 0
    mock = lambda do |_tag|
      call_count += 1
      @mock_response.deep_dup
    end

    @scanner.stub(:fetch_tag_stats, mock) do
      results = @scanner.scan(topics: ["Topic A", "Topic B"])
      assert_equal 2, results.length
    end
  end

  test "scan calculates works from fandom breakdown when numworks is 0" do
    @scanner.stub(:fetch_tag_stats, @mock_response) do
      results = @scanner.scan(topics: ["Test"])
      result = results.first

      expected_total = 92775 + 27378 + 8059 # Sum of fandom counts
      assert_equal expected_total, result[:raw_data][:ao3_works]
    end
  end

  test "scan uses numworks when nonzero" do
    response = @mock_response.deep_dup
    response["numworks"] = 150000

    @scanner.stub(:fetch_tag_stats, response) do
      results = @scanner.scan(topics: ["Test"])
      assert_equal 150000, results.first[:raw_data][:ao3_works]
    end
  end

  test "test_connection returns success on valid response" do
    @scanner.stub(:fetch_tag_stats, @mock_response) do
      result = @scanner.test_connection
      assert result[:success]
      assert_includes result[:message], "fandomstats.org"
      assert_includes result[:message], "3 fandoms"
    end
  end

  test "test_connection returns failure on nil response" do
    @scanner.stub(:fetch_tag_stats, nil) do
      result = @scanner.test_connection
      assert_not result[:success]
    end
  end

  test "test_connection returns failure on error response" do
    @scanner.stub(:fetch_tag_stats, { "message" => "error" }) do
      result = @scanner.test_connection
      assert_not result[:success]
    end
  end

  test "momentum calculation weights shipping engagement" do
    # High shipping ratio should boost momentum
    high_shipping = @scanner.send(:calculate_momentum, 100000, 70000, 10000, { "Fluff" => 5000 })
    low_shipping = @scanner.send(:calculate_momentum, 100000, 10000, 70000, { "Fluff" => 5000 })
    assert high_shipping > low_shipping
  end

  test "momentum returns 0 for zero works" do
    score = @scanner.send(:calculate_momentum, 0, 0, 0, {})
    assert_equal 0.0, score
  end
end
