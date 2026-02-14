module Designs
  class GenerationPipeline
    VARIANT_COUNT = 4
    DESIGN_STYLES = %w[watercolor anime_style fantasy_art chibi minimalist pop_art].freeze

    attr_reader :total_cost

    def initialize(cultural_token_id:, template_id: nil, variant_count: VARIANT_COUNT)
      @token = CulturalToken.find(cultural_token_id)
      @niche = @token.niche
      @template_id = template_id
      @variant_count = variant_count.clamp(1, 6)
      @total_cost = 0.0
      @generator = Designs::GeminiGenerator.new
    end

    def call
      @token.designs_pending!

      designs = generate_variants
      @token.designs_ready!

      { designs: designs, total_cost: @total_cost }
    rescue StandardError => e
      Rails.logger.error("Design generation failed for token #{@token.id}: #{e.message}")
      raise
    end

    private

    def generate_variants
      styles = select_styles
      styles.map do |style|
        generate_single(style)
      end
    end

    def select_styles
      DESIGN_STYLES.sample(@variant_count)
    end

    def generate_single(style)
      prompt = build_prompt(style)
      result = @generator.generate(prompt: prompt, style: style)

      design = Design.create!(
        cultural_token: @token,
        design_type: design_type_for(@token.token_type),
        style: style,
        prompt_used: prompt,
        generation_cost: result[:estimated_cost],
        status: :pending_review
      )

      @total_cost += result[:estimated_cost]
      design
    end

    def build_prompt(style)
      variables = {
        token_value: @token.value,
        token_type: @token.token_type,
        niche_name: @niche.name,
        style: style
      }

      composer = Prompts::TemplateComposer.new(variables)
      main_prompt = "Generate a #{style} design of #{@token.value} " \
                    "from the #{@niche.name} community. " \
                    "Token type: #{@token.token_type}."
      composer.compose(main_prompt)
    end

    def design_type_for(token_type)
      case token_type
      when "character" then "art_print"
      when "quote", "phrase" then "sticker"
      when "symbol" then "graphic"
      when "meme" then "poster"
      else "graphic"
      end
    end
  end
end
