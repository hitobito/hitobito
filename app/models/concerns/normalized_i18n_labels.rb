#  Copyright (c) 2012-2014, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Extend NormalizedLabels to only store a label in the default language, if available.
module NormalizedI18nLabels
  extend ActiveSupport::Concern
  include NormalizedLabels

  included do
    class_attribute :labels_translations_key
  end

  def translated_label
    self.class.translate_label(label)
  end

  def translated_label=(value)
    self.label = value
  end

  private

  def normalize_label
    return if label.blank?

    super
    normalize_translated_label
  end

  def normalize_translated_label
    # Translate the label back to default language, if translation is available
    label_translations = I18n.t(labels_translations_key).invert
    if label_translations.key?(label)
      self.label = I18n.t("#{labels_translations_key}.#{label_translations[label]}",
        locale: I18n.default_locale)
    end
  end

  module ClassMethods
    def translate_label(label)
      return label if label.blank?

      I18n.t("#{labels_translations_key}.#{label.downcase}",
        default: label)
    end

    # Translate the labels, if translation is available
    def available_labels = super.collect { |l| translate_label(l) }

    # Translate the labels, if translation is available
    def used_labels = super.collect { |l| translate_label(l) }
  end
end
