module Sources
  # Upserts TrendSignal records from source scan results and creates
  # corresponding SignalSnapshot entries for history tracking.
  #
  # @example
  #   Sources::SignalUpsert.call([
  #     { source: "AO3", topic: "Good Omens", description: "...", momentum_score: 7.5, raw_data: {} }
  #   ])
  class SignalUpsert
    # Processes an array of scan results into TrendSignal + SignalSnapshot records.
    #
    # @param results [Array<Hash>] Array of result hashes from source scanners
    # @return [Integer] Number of signals upserted
    def self.call(results)
      return 0 if results.blank?

      count = 0

      results.each do |result|
        signal = TrendSignal.find_or_initialize_by(
          source: result[:source],
          topic: result[:topic]
        )

        signal.description = result[:description] if result[:description].present?
        signal.momentum_score = result[:momentum_score] if result[:momentum_score]
        signal.first_seen ||= Time.current
        signal.last_updated = Time.current
        signal.status ||= "new"

        # Merge raw_data without overwriting existing keys
        existing_raw = signal.raw_data.is_a?(Hash) ? signal.raw_data : {}
        new_raw = result[:raw_data].is_a?(Hash) ? result[:raw_data] : {}
        signal.raw_data = existing_raw.merge(new_raw)

        if signal.save
          # Create snapshot for history tracking
          signal.signal_snapshots.create!(
            momentum_score: signal.momentum_score,
            source_metrics: result[:raw_data] || {},
            captured_at: Time.current
          )
          count += 1
        else
          Rails.logger.warn("SignalUpsert failed for #{result[:source]}/#{result[:topic]}: #{signal.errors.full_messages.join(", ")}")
        end
      rescue => e
        Rails.logger.error("SignalUpsert error for #{result[:source]}/#{result[:topic]}: #{e.message}")
        next
      end

      count
    end
  end
end
