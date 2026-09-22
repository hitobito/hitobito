# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# One-time backfill turning MailingList#preferred_labels free text into
# ContactAccountCategory#key values (see #4482). For each stored label, tries in
# order: does it already match a category's own key? does it match one of a
# category's translated names? does it match an old label from
# ContactAccountCategoryMigrationJob::LABEL_KEY_MAPPING, which was already built for
# this exact free-text-label -> category cascade in #4359? A label that resolves to
# none of these is left untouched, since MailRelay::AddressList keeps matching it
# against AdditionalEmail#label.
class MailingListPreferredLabelsMigrationJob < BaseJob
  self.parameters = []

  LEGACY_LABEL_MAPPING = ContactAccountCategoryMigrationJob::LABEL_KEY_MAPPING
    .fetch("AdditionalEmail", {}).fetch("Person", {})

  def perform
    categories = MailingList.preferred_label_categories.includes(:translations)
    keys = categories.map(&:key)
    label_to_key = build_label_to_key_index(categories)

    MailingList.find_each do |list|
      next if list.preferred_labels.blank?

      list.preferred_labels = list.preferred_labels.map { |label|
        resolve(label, keys, label_to_key)
      }
      list.save!(validate: false) if list.changed?
    end
  end

  private

  def resolve(label, keys, label_to_key)
    normalized = label.to_s.strip
    return normalized if keys.include?(normalized)

    label_to_key[normalized.downcase] || normalized
  end

  def build_label_to_key_index(categories)
    index = {}
    categories.each do |category|
      category.translations.each { |t| index[t.name.to_s.downcase] = category.key }
    end
    LEGACY_LABEL_MAPPING.each do |key, legacy_labels|
      legacy_labels.each { |legacy| index[legacy.downcase] ||= key.to_s }
    end
    index
  end
end
