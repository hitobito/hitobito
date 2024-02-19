# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttr
  extend ActiveSupport::Concern

  included do
    after_save :save_mounted_attributes
    has_many :mounted_attributes, as: :entry, autosave: false
  end

  def save_mounted_attributes
    self.class.mounted_attr_configs.each do |c|
      value = send(c.attr_name)
      next unless value.present?

      entry = mounted_attr_entry(c.attr_name)

      # do not persist a record when default value
      next if entry.unset? && value == c.default

      entry.value = value
      entry.save! if entry.value_changed?
    end
  end

  def mounted_attr_entry(attr_name)
    mounted_attributes.find_or_initialize_by(key: attr_name)
  end

  module ClassMethods

    cattr_reader :mounted_attr_registry
    @@mounted_attr_registry = ::MountedAttributes::Registry.new

    def mounted_attr_configs
      mounted_attr_registry.configs_for(self)
    end

    def mounted_attr_configs_by_category
      {}.tap do |h|
        mounted_attr_configs.each do |c|
          category = c.category || :default
          h[category] = (h[category] || []) << c
        end
        h[:default] = h.delete(:default) if h[:default]
      end
    end

    def mounted_attr_names
      mounted_attr_configs.collect(&:attr_name)
    end

    private

    def mounted_attr(attr, attr_type, options = {})
      config = mounted_attr_registry.register(self, attr, attr_type, options)

      define_mounted_attr_getter(config)
      define_mounted_attr_setter(config)
      define_mounted_attr_type_method(config)
      define_mounted_attr_validations(config)
    end

    def define_mounted_attr_getter(config)
      define_method(config.attr_name) do
        var_name = "@#{config.attr_name}"
        value = if instance_variable_defined?(var_name)
                  instance_variable_get(var_name)
                else
                  mounted_attr_entry(config.attr_name).casted_value
                end

        return config.default if
          !config.default.nil? && (value.nil? || value.try(:empty?) || value.try(:zero?))

        value
      end
    end

    def define_mounted_attr_setter(config)
      define_method("#{config.attr_name}=") do |value|
        instance_variable_set("@#{config.attr_name}", value)
        value
      end
    end

    # This is used to determine the type of the attribute in the template.
    # See `UtilityHelper#column_type`
    def define_mounted_attr_type_method(config)
      define_method("#{config.attr_name}_type") do
        config.attr_type
      end
    end

    def define_mounted_attr_validations(config)
      class_eval do
        unless config.null
          if config.attr_type == :boolean
            validates config.attr_name, inclusion: { in: [true, false], message: :blank }
          else
            validates config.attr_name, presence: true
          end
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
