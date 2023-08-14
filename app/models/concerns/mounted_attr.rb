
module MountedAttr
  extend ActiveSupport::Concern

  included do
    class_attribute :mounted_attr_categories
  end

  module ClassMethods
    cattr_reader :store
    @@store = ::MountedAttributes::Store.new

    def mounted_attr(attr, attr_type, options = {})
      config = store.register(self, attr, attr_type, options)

      define_mounted_attr_getter(config)
      define_mounted_attr_setter(config)

      define_mounted_attr_validations(config)
    end

    private

    def define_mounted_attr_getter(config)
      define_method("mounted_#{config.attr_name}") do
        (instance_variable_get("@mounted_#{config.attr_name}") ||
                                instance_variable_set("@mounted_#{config.attr_name}",
                                MountedAttribute.find_by(entry_id: self.id,
                                                         entry_type: config.target_class,
                                                         key: config.attr_name))
        )
      end

      define_method(config.attr_name) do
        send("mounted_#{config.attr_name}")&.casted_value || config.default
      end
    end

    def define_mounted_attr_setter(config)
      define_method("#{config.attr_name}=") do |value|
        return if value.empty?

        entry = send("mounted_#{config.attr_name}") || MountedAttribute.new(entry_id: self.id,
                                                                            entry_type: config.target_class,
                                                                            key: config.attr_name)
        entry.value = value
        entry.save!

        value
      end
    end

    def define_mounted_attr_validations(config)
      class_eval do
        unless config.null
          validates config.attr_name, presence: true
        end

        if config.enum.present?
          validates config.attr_name, inclusion: { in: config.enum }, allow_nil: config.null
        end

        if config.default.present?
          before_validation do |e|
            e.send("#{config.attr_name}=", config.default) if e.send(config.attr_name).nil?
          end
        end
      end
    end
  end
end
