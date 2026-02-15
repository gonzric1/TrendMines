require "test_helper"

class WebhookDeliveryTest < ActiveSupport::TestCase
  test "should create valid webhook delivery" do
    delivery = WebhookDelivery.new(
      event_type: "listing.created",
      payload: { listing_id: 1 },
      url: "https://example.com/webhook"
    )
    assert delivery.valid?
  end

  test "should require event_type" do
    delivery = WebhookDelivery.new(
      payload: { listing_id: 1 },
      url: "https://example.com/webhook"
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:event_type], "can't be blank"
  end

  test "should require payload" do
    delivery = WebhookDelivery.new(
      event_type: "listing.created",
      url: "https://example.com/webhook"
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:payload], "can't be blank"
  end

  test "should require url" do
    delivery = WebhookDelivery.new(
      event_type: "listing.created",
      payload: { listing_id: 1 }
    )
    assert_not delivery.valid?
    assert_includes delivery.errors[:url], "can't be blank"
  end

  test "should default status to pending" do
    delivery = WebhookDelivery.new(
      event_type: "listing.created",
      payload: { listing_id: 1 },
      url: "https://example.com/webhook"
    )
    assert_equal "pending", delivery.status
  end

  test "should default attempts to 0" do
    delivery = WebhookDelivery.new(
      event_type: "listing.created",
      payload: { listing_id: 1 },
      url: "https://example.com/webhook"
    )
    assert_equal 0, delivery.attempts
  end

  test "enum values map correctly" do
    assert_equal "pending", WebhookDelivery.statuses[:pending]
    assert_equal "delivered", WebhookDelivery.statuses[:delivered]
    assert_equal "failed", WebhookDelivery.statuses[:failed]
  end

  test "pending scope returns only pending deliveries" do
    results = WebhookDelivery.pending
    results.each do |d|
      assert_equal "pending", d.status
    end
  end

  test "failed scope returns only failed deliveries" do
    results = WebhookDelivery.failed
    results.each do |d|
      assert_equal "failed", d.status
    end
  end

  test "recent scope orders by created_at desc" do
    results = WebhookDelivery.recent
    timestamps = results.pluck(:created_at)
    assert_equal timestamps, timestamps.sort.reverse
  end
end
