require "net/http"

module Webhooks
  class Deliver
    def initialize(delivery)
      @delivery = delivery
    end

    def call
      @delivery.update!(
        attempts: @delivery.attempts + 1,
        last_attempt_at: Time.current
      )

      response = Net::HTTP.post(
        URI.parse(@delivery.url),
        @delivery.payload.to_json,
        "Content-Type" => "application/json"
      )

      @delivery.update!(
        status: :delivered,
        response_code: response.code.to_i,
        response_body: response.body&.truncate(1000)
      )
    rescue StandardError => e
      @delivery.update!(
        response_code: response&.code&.to_i,
        response_body: e.message.truncate(1000)
      )

      if @delivery.attempts >= 3
        @delivery.update!(status: :failed)
      end

      raise
    end
  end
end
