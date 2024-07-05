#  Copyright (c) 2014, Insieme Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Define a setter methods that accept translated values
# in the current language as well as the system defined values.
# This is mainly used for importing values.
module I18nSettable
  extend ActiveSupport::Concern

  module ClassMethods
    # Define a setter for the given attribute that accepts translated values
    # in the current language as well as the system defined values.
    # Translated values are automatically converted.
    def i18n_setter(attr, possible_values)
      i18n_prefix = "activerecord.attributes.#{name.underscore}.#{attr.to_s.pluralize}"

      define_method(:"#{attr}=") do |value|
        super(value)

        normalized = value.to_s.strip.downcase
        possible_values.each do |v|
          translated = I18n.t("#{i18n_prefix}.#{v.presence || "_nil"}")
          super(v) if translated.downcase == normalized
        end

        value
      end
    end

    # Defines a setter for the given boolean attributes that accept translated
    # boolean Strings (e.g. Ja, nein) as well as the regular allowed boolean values.
    # Translated values are automatically converted to boolean.
    def i18n_boolean_setter(*attrs)
      attrs.each do |attr|
        define_method(:"#{attr}=") do |value|
          super(normalize_i18n_boolean(value))
        end
      end
    end
  end

  private

  def normalize_i18n_boolean(value)
    normalized = value.to_s.strip.downcase
    if I18n.t("global.yes").downcase == normalized
      true
    elsif value.blank? || I18n.t("global.no").downcase == normalized
      false
    else
      normalized
    end
  end
end
