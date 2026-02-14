module Signals
  class PromoteToNiche
    def initialize(signal, params = {})
      @signal = signal
      @params = params
    end

    def call
      ActiveRecord::Base.transaction do
        niche = @signal.niches.create!(
          name: @params[:name] || @signal.topic,
          description: @params[:description] || @signal.description,
          community_type: @params[:community_type] || "general",
          status: "discovered",
          discovered_at: Time.current
        )

        @signal.update!(status: :promoted)

        niche
      end
    end
  end
end
