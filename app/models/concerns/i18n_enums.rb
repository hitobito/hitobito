# frozen_string_literal: true

#  Copyright (c) 2014, 2019, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module I18nEnums
  extend ActiveSupport::Concern

  NIL_KEY = "_nil"

  module ClassMethods
    # possible_values should be an array of strings or a proc that returns an array of strings
    def i18n_enum(attr, possible_values = nil,
      scopes: false, queries: false, validations: true,
      key: nil, i18n_prefix: nil, &block)
      raise "either possible_values or a block must be given" unless possible_values || block
      raise "cannot generate scopes/queries using a block" if block && (scopes || queries)

      key ||= attr.to_s.pluralize
      prefix = i18n_prefix || "activerecord.attributes.#{name.underscore}.#{key}"
      possible = if block_given?
        ->(record) { record.instance_exec(&block) }
      elsif possible_values.respond_to?(:call)
        possible_values
      else
        ->(_) { possible_values }
      end

      if validations
        validate do
          allowed = possible.call(self) || []
          value = send(attr)
          if value.present? && !allowed.include?(value)
            errors.add(attr, :inclusion, value: value)
          end
        end
      end

      define_method(:"#{attr}_label") do |value = nil|
        value ||= send(attr)
        if value.present?
          I18n.t("#{prefix}.#{value.to_s.downcase}")
        else
          I18n.t("#{prefix}.#{NIL_KEY}", default: "")
        end
      end

      define_singleton_method(:"#{attr}_labels") do |record = nil|
        possible.call(record).map do |value|
          [value.to_sym, I18n.t("#{prefix}.#{value}")]
        end.to_h
      end

      if queries || scopes
        possible.call(nil).each do |value|
          scope value.to_sym, -> { where(attr => value) } if scopes
          define_method(:"#{value}?") { self[attr] == value } if queries
        end
      end
    end
  end
end

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
