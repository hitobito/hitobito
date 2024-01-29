module MountedAttrs
  class EnumSelect

    def initialize(template, mounted_attr_config, form)
      @config = mounted_attr_config
      @template = template
      @f = form
    end

    def render
      f.select(config.attr_name, options, { include_blank: config.null },
        class: 'form-select form-select-sm')
    end    

    private

    attr_reader :template, :config, :f
    delegate :t, to: :template

    def options
      config.enum.map do |o|
        [option_label(o), o]
      end
    end

    def option_label(option)
      class_name = f.object.object.class.to_s.underscore
      t("activerecord.attributes.#{class_name}.#{config.attr_name}s.#{option}")
    end
  end
end
