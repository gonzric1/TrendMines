# Background job that scans all configured external sources for trend signals.
# Runs hourly via Solid Queue recurring schedule. Checks each source's
# last scan time against its configured frequency before scanning.
class SignalScanJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  SOURCE_MAP = {
    "reddit" => "Sources::Reddit",
    "tumblr" => "Sources::Tumblr",
    "ao3" => "Sources::FandomStats",
    "google_trends" => "Sources::GoogleTrends"
  }.freeze

  def perform
    topics = gather_topics
    return if topics.empty?

    SOURCE_MAP.each do |source_name, class_name|
      next unless source_due?(source_name)

      scanner = class_name.constantize.new
      next unless scanner.configured?

      scan_source(scanner, source_name, topics)
    rescue => e
      Rails.logger.error("SignalScanJob error for #{source_name}: #{e.message}")
      Rails.logger.error(e.backtrace.first(5).join("\n"))
      next
    end
  end

  private

  # Collects topics from active signals plus any configured default topics.
  def gather_topics
    topics = TrendSignal.active.pluck(:topic).uniq

    # Add default topics from scanning settings if configured
    defaults = Setting.find_by(key: "scanning.default_topics")
    if defaults&.value.is_a?(Array)
      topics.concat(defaults.value)
    elsif defaults&.value.is_a?(String) && defaults.value.present?
      topics.concat(defaults.value.split(",").map(&:strip))
    end

    topics.uniq.compact_blank
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

  # Runs a single source scan and records results + scan time.
  def scan_source(scanner, source_name, topics)
    Rails.logger.info("SignalScanJob: scanning #{source_name} (#{topics.length} topics)")

    results = scanner.scan(topics: topics)
    upserted = Sources::SignalUpsert.call(results)

    Rails.logger.info("SignalScanJob: #{source_name} returned #{results.length} results, upserted #{upserted}")

    # Record scan time
    record_scan_time(source_name)
  end

  def record_scan_time(source_name)
    setting = Setting.find_or_initialize_by(key: "scanning.#{source_name}_last_scan")
    setting.category = "scanning"
    setting.value = Time.current.iso8601
    setting.description ||= "Last scan time for #{source_name}"
    setting.save!
  end
end
