module Signals
  # Enriches a TrendSignal with AO3 fandom data.
  # Uses Ao3TagMapper to find the canonical tag, then fetches stats.
  class EnrichWithAo3
    # @param signal [TrendSignal] The signal to enrich
    # @return [Boolean] Whether enrichment was applied
    def self.call(signal)
      new(signal).call
    end

    def initialize(signal)
      @signal = signal
    end

    def call
      return false if already_enriched?

      tag = Ai::Ao3TagMapper.call(@signal.topic)
      return false if tag.nil?

      scanner = Sources::FandomStats.new
      results = scanner.scan(topics: [tag])
      return false if results.empty?

      merge_ao3_data(results.first)
      true
    rescue => e
      Rails.logger.error("EnrichWithAo3 error for signal #{@signal.id} '#{@signal.topic}': #{e.message}")
      false
    end

    private

    def parse_raw_data(data)
      return data if data.is_a?(Hash)
      return JSON.parse(data) if data.is_a?(String)
      {}
    rescue JSON::ParserError
      {}
    end

    def already_enriched?
      raw = parse_raw_data(@signal.raw_data)
      raw["ao3_enriched"].present?
    end

    def merge_ao3_data(result)
      raw_data = parse_raw_data(@signal.raw_data)
      ao3_raw = result[:raw_data] || {}

      enrichment = {
        "ao3_enriched" => true,
        "ao3_works" => ao3_raw[:ao3_works],
        "ao3_shipping_ratio" => ao3_raw[:shipping_ratio],
        "ao3_top_relationships" => ao3_raw[:top_relationships],
        "ao3_top_freeform_tags" => ao3_raw[:top_freeform_tags]
      }

      @signal.update!(raw_data: raw_data.merge(enrichment))
    end
  end
end
