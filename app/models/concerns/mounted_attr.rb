
module MountedAttr
  extend ActiveSupport::Concern

  module ClassMethods
    def mounted_attr(attr, attr_type, options = {})
      options[:null] ||= true

      define_mounted_attr_getter(attr, attr_type)
      define_mounted_attr_setter(attr)

      class_eval do
        unless options[:null]
          validates attr, presence: true
        end

        if options[:enum].present?
          validates attr, inclusion: { in: options[:enum] }, allow_nil: options[:null]
        end

        if options[:default].present?
          before_validation do |e|
            e.send("#{attr}=", options[:default]) if e.send(attr).nil?
          end
        end
      end
    end

    private

    def define_mounted_attr_getter(attr, attr_type)
      define_method("mounted_#{attr}") do
        (instance_variable_get("@mounted_#{attr}") ||
          instance_variable_set("@mounted_#{attr}",
                                MountedAttribute.find_by(entry_id: self.id,
                                                         entry_type: self.class.sti_name,
                                                         key: attr))
        )
      end

      define_method(attr) do
        send("mounted_#{attr}")&.casted_value(attr_type)
      end
    end

    def define_mounted_attr_setter(attr)
      define_method("#{attr}=") do |value|
        entry = send("mounted_#{attr}") || MountedAttribute.new(entry_id: self.id,
                                                                entry_type: self.class.sti_name,
                                                                key: attr)

        entry.value = value
        entry.save!

        value
      end
    end
  end
end
