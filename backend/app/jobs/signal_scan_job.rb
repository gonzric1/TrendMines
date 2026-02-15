# Background job that scans all configured external sources for trend signals.
# Runs hourly via Solid Queue recurring schedule.
#
# Two modes per source:
#   1. Discovery — find NEW trends automatically (no input needed)
#   2. Monitoring — re-check topics from existing active TrendSignals
class SignalScanJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  SOURCE_MAP = {
    "reddit" => "Sources::Reddit",
    "tumblr" => "Sources::Tumblr",
    "google_trends" => "Sources::GoogleTrends"
  }.freeze

  def perform
    SOURCE_MAP.each do |source_name, class_name|
      next unless source_due?(source_name)

      scanner = class_name.constantize.new
      next unless scanner.configured?

      # Phase 1: Discovery — find new trends (no topics needed)
      run_discovery(scanner, source_name)

      # Phase 2: Monitoring — re-check known active topics
      topics = TrendSignal.active.pluck(:topic).uniq
      run_monitoring(scanner, source_name, topics) if topics.any?

      record_scan_time(source_name)
    rescue => e
      Rails.logger.error("SignalScanJob error for #{source_name}: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      next
    end

    # Enqueue post-scan processing (enrichment, correlation, promotion, token extraction)
    SignalProcessingJob.perform_later
  end

  private

  def run_discovery(scanner, source_name)
    Rails.logger.info("SignalScanJob: discovering from #{source_name}")

    results = scanner.discover
    upserted = Sources::SignalUpsert.call(results)

    Rails.logger.info("SignalScanJob: #{source_name} discovered #{results.length} signals, upserted #{upserted}")
  rescue => e
    Rails.logger.error("SignalScanJob discovery error for #{source_name}: #{e.message}")
  end

  def run_monitoring(scanner, source_name, topics)
    Rails.logger.info("SignalScanJob: monitoring #{topics.length} topics from #{source_name}")

    results = scanner.scan(topics: topics)
    upserted = Sources::SignalUpsert.call(results)

    Rails.logger.info("SignalScanJob: #{source_name} monitored #{results.length} results, upserted #{upserted}")
  rescue => e
    Rails.logger.error("SignalScanJob monitoring error for #{source_name}: #{e.message}")
  end

  # Checks if a source is due for scanning based on its frequency and last scan time.
  def source_due?(source_name)
    frequency_setting = Setting.find_by(key: "scanning.#{source_name}_frequency")
    return true unless frequency_setting # No frequency = always scan

    frequency_hours = frequency_setting.value
    return true unless frequency_hours.is_a?(Numeric) && frequency_hours > 0

    last_scan_setting = Setting.find_by(key: "scanning.#{source_name}_last_scan")
    return true unless last_scan_setting&.value.present?

    last_scan = Time.parse(last_scan_setting.value)
    Time.current >= last_scan + frequency_hours.hours
  rescue ArgumentError
    true # Invalid timestamp = scan now
  end

  def record_scan_time(source_name)
    setting = Setting.find_or_initialize_by(key: "scanning.#{source_name}_last_scan")
    setting.category = "scanning"
    setting.value = Time.current.iso8601
    setting.description ||= "Last scan time for #{source_name}"
    setting.save!
  end
end
