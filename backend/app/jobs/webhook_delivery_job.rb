class WebhookDeliveryJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(webhook_delivery_id)
    delivery = WebhookDelivery.find(webhook_delivery_id)
    Webhooks::Deliver.new(delivery).call
  end
end
