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
      value = mounted_attr_value(c.attr_name)
      entry = mounted_attr_entry(c.attr_name, value)

      next if value == c.default && entry.new_record? # Do not persist default value for new record

      entry.value = value
      entry.save! if entry.value_changed? # Only save if the value has changed
    end
  end

  private

  def mounted_attr_entry(attr_name, value = nil)
    mounted_attributes.find_by(key: attr_name) ||
      MountedAttribute.new(entry: self, key: attr_name, value: value)
  end

  def mounted_attr_cached?(attr_name)
    instance_variable_defined?("@#{attr_name}")
  end

  def mounted_attr_cached_value(attr_name)
    instance_variable_get("@#{attr_name}")
  end

  def mounted_attr_cache_value(attr_name, value)
    instance_variable_set("@#{attr_name}", value)
  end

  def mounted_attr_value(attr_name)
    if mounted_attr_cached?(attr_name)
      # Use the MountedAttribute accessor which handles type casting and default values.
      MountedAttribute.new(
        entry: self,
        key: attr_name,
        value: mounted_attr_cached_value(attr_name)
      ).value
    else
      mounted_attr_entry(attr_name).value
    end
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

    # `attr_type` should be a type symbol registered with the ActiveModel type registry.
    # See `ActiveModel::Type` for default types or register your own.
    def mounted_attr(attr, attr_type, options = {})
      config = mounted_attr_registry.register(self, attr, attr_type, options)

      define_mounted_attr_getter(config)
      define_mounted_attr_setter(config)
      define_mounted_attr_type_lookup_method(config)
      define_mounted_attr_validations(config)
    end

    def define_mounted_attr_getter(config)
      define_method(config.attr_name) do
        mounted_attr_value(config.attr_name)
      end
    end

    def define_mounted_attr_setter(config)
      define_method("#{config.attr_name}=") do |value|
        mounted_attr_cache_value(config.attr_name, value)
      end
    end

    # This is used to determine the type of the attribute in the template.
    # See `UtilityHelper#column_type`
    def define_mounted_attr_type_lookup_method(config)
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
