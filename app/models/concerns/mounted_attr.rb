# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MountedAttr
  extend ActiveSupport::Concern

  included do
    class_attribute :mounted_attr_categories
    after_save :save_mounted_attributes
    has_many :mounted_attributes, as: :entry, autosave: false
  end

  def save_mounted_attributes
    self.class.mounted_attribute_configs.each do |c|
      value = send(c.attr_name)
      next unless value.present?

      entry = mounted_attr_entry(c.attr_name)

      next if (entry.value.nil? || entry.casted_value.zero?) && value == c.default

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

    def mounted_attribute_configs
      mounted_attr_registry.configs_for(self)
    end

    private

    def mounted_attr(attr, attr_type, options = {})
      config = mounted_attr_registry.register(self, attr, attr_type, options)

      define_mounted_attr_getter(config)
      define_mounted_attr_setter(config)

      define_mounted_attr_validations(config)
    end

    def define_mounted_attr_getter(config)
      define_method(config.attr_name) do
        instance_variable_get("@#{config.attr_name}") ||
          mounted_attr_entry(config.attr_name).casted_value ||
          config.default
      end
    end

    def define_mounted_attr_setter(config)
      define_method("#{config.attr_name}=") do |value|
        instance_variable_set("@#{config.attr_name}", value)
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
