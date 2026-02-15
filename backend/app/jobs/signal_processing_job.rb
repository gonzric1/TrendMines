# Post-scan orchestrator that processes signals through enrichment, correlation,
# auto-promotion, and cultural token extraction.
# Runs after SignalScanJob or on its own schedule as a safety net.
class SignalProcessingJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform
    signals = TrendSignal.active.to_a
    Rails.logger.info("SignalProcessingJob: processing #{signals.length} active signals")

    # Phase 1: Enrich signals with AO3 data
    enrich_signals(signals)

    # Phase 2: Correlate cross-source signals
    correlate_signals(signals)

    # Phase 3: Auto-promote eligible signals
    new_niches = auto_promote_signals(signals)

    # Phase 4: Extract cultural tokens for new niches
    extract_tokens(new_niches)

    Rails.logger.info("SignalProcessingJob: complete. #{new_niches.length} niches created.")
  end

  private

  def enrich_signals(signals)
    signals.each do |signal|
      Signals::EnrichWithAo3.call(signal)
    rescue => e
      Rails.logger.error("SignalProcessingJob enrich error for signal #{signal.id}: #{e.message}")
    end
  end

  def correlate_signals(signals)
    # Only correlate signals that aren't already correlated
    uncorrelated = signals.select { |s| s.correlated_signal_id.nil? }

    uncorrelated.each do |signal|
      Signals::CorrelateSources.call(signal)
    rescue => e
      Rails.logger.error("SignalProcessingJob correlate error for signal #{signal.id}: #{e.message}")
    end
  end

  def auto_promote_signals(signals)
    new_niches = []

    # Reload signals to get fresh state after enrichment/correlation
    signals.each do |signal|
      signal.reload
      niche = Signals::AutoPromote.call(signal)
      new_niches << niche if niche
    rescue => e
      Rails.logger.error("SignalProcessingJob promote error for signal #{signal.id}: #{e.message}")
    end

    new_niches
  end

  def extract_tokens(niches)
    niches.each do |niche|
      tokens = Ai::ExtractCulturalTokens.call(niche)
      Rails.logger.info("SignalProcessingJob: extracted #{tokens.length} tokens for niche #{niche.id} '#{niche.name}'")

      Niches::CalculateScorecard.new(niche).call
    rescue => e
      Rails.logger.error("SignalProcessingJob extract error for niche #{niche.id}: #{e.message}")
    end
  end
end
