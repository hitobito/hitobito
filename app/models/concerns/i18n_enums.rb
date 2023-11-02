# frozen_string_literal: true

#  Copyright (c) 2014, 2019, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

module I18nEnums
  extend ActiveSupport::Concern

  NIL_KEY = '_nil'

  module ClassMethods

    # possible_values should be an array of strings or a proc that returns an array of strings
    def i18n_enum(attr, possible_values = nil,
                  scopes: false, queries: false,
                  key: nil, i18n_prefix: nil, &block)

      raise 'either possible_values or a block must be given' unless possible_values || block_given?
      raise 'cannot generate scopes/queries using a block' if block_given? && (scopes || queries)

      key ||= attr.to_s.pluralize
      prefix = i18n_prefix || "activerecord.attributes.#{name.underscore}.#{key}"

      validates attr, inclusion: { in: block || possible_values }, allow_blank: true

      define_method("#{attr}_label") do |value = nil|
        value ||= send(attr)
        I18n.t("#{prefix}.#{value.to_s.downcase.presence || NIL_KEY}")
      end

      define_singleton_method("#{attr}_labels") do
        I18n.t(prefix).except(NIL_KEY.to_sym)
      end

      possible_values&.each do |value|
        scope value.to_sym, -> { where(attr => value) }  if scopes
        define_method("#{value}?") { self[attr] == value } if queries
      end
    end

  end
end

# rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
