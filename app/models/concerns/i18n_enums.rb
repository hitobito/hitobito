#  Copyright (c) 2014, 2019, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module I18nEnums
  extend ActiveSupport::Concern

  NIL_KEY = '_nil'.freeze

  module ClassMethods

    def i18n_enum(attr, possible_values, scopes: false, queries: false, key: nil) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      key ||= attr.to_s.pluralize
      i18n_prefix = "activerecord.attributes.#{name.underscore}.#{key}"

      validates attr, inclusion: possible_values, allow_blank: true

      define_method("#{attr}_label") do |value = nil|
        value ||= send(attr)
        I18n.t("#{i18n_prefix}.#{value.to_s.downcase.presence || NIL_KEY}")
      end

      define_singleton_method("#{attr}_labels") do
        I18n.t(i18n_prefix).except(NIL_KEY.to_sym)
      end

      possible_values.each do |value|
        scope value.to_sym, -> { where(attr => value) }  if scopes
        define_method("#{value}?") { self[attr] == value } if queries
      end
    end

  end
end
