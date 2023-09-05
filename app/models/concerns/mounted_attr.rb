# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

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

      define_mounted_entry_getter(config)

      if config.attr_type == :picture
        define_mounted_picture(config)
      end

      define_mounted_attr_getter(config)
      define_mounted_attr_setter(config)

      define_mounted_attr_validations(config)
    end

    private

    def define_mounted_entry_getter(config)
      define_method("mounted_#{config.attr_name}") do
        (instance_variable_get("@mounted_#{config.attr_name}") ||
         instance_variable_set("@mounted_#{config.attr_name}",
                               config.mounted_attribute_class.find_or_initialize_by(
                                 entry_id: self.id,
                                 entry_type: config.target_class,
                                 key: config.attr_name
                               ))
        )
      end
    end

    def define_mounted_picture(config)
      define_method("remove_#{config.attr_name}") do
        false
      end

      define_method("remove_#{config.attr_name}=") do |deletion_param|
        if %w(1 yes true).include?(deletion_param.to_s.downcase)
          send(config.attr_name).purge_later
        end
      end
    end

    def define_mounted_attr_getter(config)
      define_method(config.attr_name) do
        send("mounted_#{config.attr_name}")&.casted_value || config.default
      end
    end

    def define_mounted_attr_setter(config)
      define_method("#{config.attr_name}=") do |value|
        return if value.blank?

        entry = send("mounted_#{config.attr_name}") ||
          config.mounted_attribute_class.new(entry_id: self.id,
                                             entry_type: config.target_class,
                                             key: config.attr_name)
        entry.value = if config.attr_type == :picture
                        value
                      else
                        value.to_s
                      end
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
