require "test_helper"
require "net/http"

class Webhooks::DeliverTest < ActiveSupport::TestCase
  setup do
    @delivery = webhook_deliveries(:pending_delivery)
  end

  test "successful delivery updates status to delivered" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:code, "200")
    mock_response.expect(:code, "200")
    mock_response.expect(:body, '{"ok": true}')

    Net::HTTP.stub(:post, mock_response) do
      Webhooks::Deliver.new(@delivery).call
    end

    @delivery.reload
    assert_equal "delivered", @delivery.status
    assert_equal 200, @delivery.response_code
    assert_equal 1, @delivery.attempts
    assert_not_nil @delivery.last_attempt_at
  end

  test "increments attempts counter" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:code, "200")
    mock_response.expect(:code, "200")
    mock_response.expect(:body, '{"ok": true}')

    assert_equal 0, @delivery.attempts

    Net::HTTP.stub(:post, mock_response) do
      Webhooks::Deliver.new(@delivery).call
    end

    @delivery.reload
    assert_equal 1, @delivery.attempts
  end

  test "failed delivery re-raises error for retry" do
    Net::HTTP.stub(:post, ->(*) { raise StandardError, "Connection refused" }) do
      assert_raises(StandardError) do
        Webhooks::Deliver.new(@delivery).call
      end
    end

    @delivery.reload
    assert_equal 1, @delivery.attempts
    assert_equal "Connection refused", @delivery.response_body
  end

  test "marks as failed after 3 attempts" do
    @delivery.update!(attempts: 2)

    Net::HTTP.stub(:post, ->(*) { raise StandardError, "Timeout" }) do
      assert_raises(StandardError) do
        Webhooks::Deliver.new(@delivery).call
      end
    end

    @delivery.reload
    assert_equal "failed", @delivery.status
    assert_equal 3, @delivery.attempts
  end

  test "does not mark as failed before 3 attempts" do
    @delivery.update!(attempts: 0)

    Net::HTTP.stub(:post, ->(*) { raise StandardError, "Timeout" }) do
      assert_raises(StandardError) do
        Webhooks::Deliver.new(@delivery).call
      end
    end

    @delivery.reload
    assert_equal "pending", @delivery.status
    assert_equal 1, @delivery.attempts
  end

  test "sets last_attempt_at timestamp" do
    mock_response = Minitest::Mock.new
    mock_response.expect(:code, "200")
    mock_response.expect(:code, "200")
    mock_response.expect(:body, '{"ok": true}')

    freeze_time do
      Net::HTTP.stub(:post, mock_response) do
        Webhooks::Deliver.new(@delivery).call
      end

      @delivery.reload
      assert_equal Time.current, @delivery.last_attempt_at
    end
  end

  test "truncates long response body" do
    long_body = "x" * 2000
    mock_response = Minitest::Mock.new
    mock_response.expect(:code, "200")
    mock_response.expect(:code, "200")
    mock_response.expect(:body, long_body)

    Net::HTTP.stub(:post, mock_response) do
      Webhooks::Deliver.new(@delivery).call
    end

    @delivery.reload
    assert @delivery.response_body.length <= 1000
  end
end
