require "test_helper"

class WebhookDeliveryJobTest < ActiveJob::TestCase
  setup do
    @delivery = webhook_deliveries(:pending_delivery)
  end

  test "enqueues job successfully" do
    assert_enqueued_with(job: WebhookDeliveryJob) do
      WebhookDeliveryJob.perform_later(@delivery.id)
    end
  end

  test "calls Webhooks::Deliver service" do
    called = false
    mock_service = proc do |delivery|
      called = true
      mock = Minitest::Mock.new
      mock.expect(:call, true)
      mock
    end

    Webhooks::Deliver.stub(:new, mock_service) do
      WebhookDeliveryJob.perform_now(@delivery.id)
    end

    assert called, "Expected Webhooks::Deliver to be called"
  end

  test "discards on ActiveRecord::RecordNotFound" do
    assert_nothing_raised do
      WebhookDeliveryJob.perform_now(-999)
    end
  end
end
