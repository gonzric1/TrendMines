module Prompts
  class TemplateComposer
    def initialize(variables = {})
      @variables = variables.transform_keys(&:to_s)
    end

    def compose(main_prompt)
      prefix = load_template("templates.design_prompt_prefix")
      suffix = load_template("templates.design_prompt_suffix")

      full = [prefix, main_prompt, suffix].compact.reject(&:empty?).join("\n\n")
      substitute_variables(full)
    end

    def compose_listing_title(variables = {})
      template = load_template("templates.listing_title_template")
      substitute_variables(template, variables)
    end

    def compose_listing_description(variables = {})
      template = load_template("templates.listing_description_template")
      substitute_variables(template, variables)
    end

    private

    def load_template(key)
      Setting.find_by(key: key)&.value.to_s
    end

    def substitute_variables(text, extra_vars = {})
      merged = @variables.merge(extra_vars.transform_keys(&:to_s))
      merged.each do |key, value|
        text = text.gsub("{#{key}}", value.to_s)
      end
      text
    end
  end
end
