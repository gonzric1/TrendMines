class DesignGenerationJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(cultural_token_ids:, template_id: nil)
    Array(cultural_token_ids).each do |token_id|
      generate_for_token(token_id, template_id)
    end
  end

  private

  def generate_for_token(token_id, template_id)
    pipeline = Designs::GenerationPipeline.new(
      cultural_token_id: token_id,
      template_id: template_id
    )
    pipeline.call
  rescue StandardError => e
    Rails.logger.error(
      "DesignGenerationJob failed for token #{token_id}: #{e.message}"
    )
    raise if Array(@cultural_token_ids_arg).size == 1
  end
end
