
module MountedAttr
  extend ActiveSupport::Concern

  included do
    class_attribute :mounted_attr_categories
  end

  module ClassMethods
    # TODO: Configurations class. Tracking mounted attrs per class including type and options
    def mounted_attr(attr, attr_type, options = {})
      options[:null] ||= true

      define_mounted_attr_getter(attr, attr_type, options)
      define_mounted_attr_setter(attr, attr_type)

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

    def define_mounted_attr_getter(attr, attr_type, options)
      define_method("mounted_#{attr}") do
        (instance_variable_get("@mounted_#{attr}") ||
          instance_variable_set("@mounted_#{attr}",
                                MountedAttribute.find_by(entry_id: self.id,
                                                         entry_type: self.class.sti_name,
                                                         key: attr))
        )
      end

      define_method(attr) do
        send("mounted_#{attr}")&.casted_value(attr_type) || options[:default]
      end
    end

    def define_mounted_attr_setter(attr, attr_type)
      define_method("#{attr}=") do |value|
        entry = send("mounted_#{attr}") || MountedAttribute.new(entry_id: self.id,
                                                                entry_type: self.class.sti_name,
                                                                key: attr)

        entry.value = if attr_type.eql? :encrypted
                        EncryptionService.encrypt(value.to_s)
                      else
                        value.to_s
                      end

        entry.save!

        value
      end
    end
  end
end
