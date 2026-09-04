# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ContactAccountCategoryMigrationJob < BaseJob
  self.parameters = []

  CONTACTABLES = %w[Person Group]
  USED_FOR_INVOICES_MODELS = [AdditionalAddress, AdditionalEmail].product(CONTACTABLES).freeze
  MODELS = [PhoneNumber, SocialAccount, AdditionalEmail, AdditionalAddress].freeze

  # Last-resort mapping from an old free-text label to a ContactAccountCategory#key,
  # used only for labels that don't already match a category's own key or one of its
  # translations (see #assign_remaining_by_label) -- e.g. a renamed concept like
  # "Privat" -> "landline", where the old label and the new category share no text.
  # Nested as contact_account_type => contactable_type => {key => [labels]} -- the
  # target key is named once, with every old label that should resolve to it listed
  # alongside. Wagons extend this by digging into (or building) the nested hashes
  # directly, e.g. LABEL_KEY_MAPPING["PhoneNumber"]["Person"][:mobile] << "natel".
  LABEL_KEY_MAPPING = {
    "PhoneNumber" => {
      "Person" => {work: ["arbeit"], landline: ["privat"]},
      "Group" => {office: ["arbeit"]}
    },
    "SocialAccount" => {
      "Person" => {x_twitter: ["twitter"], website: ["homepage", "webpage"],
                   instagram: ["insta", "instagramm"]},
      "Group" => {x_twitter: ["twitter"], website: ["homepage", "webpage"],
                  instagram: ["insta", "instagramm"]}
    },
    "AdditionalEmail" => {
      "Person" => {work: ["arbeit", "geschäft"],
                   private: ["e-mail", "email", "mail", "ja", "persöhnlich"]},
      "Group" => {office: ["arbeit"]}

    },
    "AdditionalAddress" => {
      "Person" => {work: ["arbeit"]}
    }
  }

  def perform
    assign_used_for_invoices
    assign_remaining_by_label
    assign_remaining_other
  end

  private

  def assign_used_for_invoices
    scope = ContactAccountCategory.used_for_invoices.includes(:translations)
    categories = categories_by_type(scope)

    USED_FOR_INVOICES_MODELS.each do |contact_account_type, contactable_type|
      category = categories[[contact_account_type.to_s, contactable_type.to_s]]
      next unless category

      accounts = contact_account_type.where(contactable_type:, category_id: nil, invoices: true)
      assign_invoices_match(accounts, category)
    end
  end

  # The invoices category is assigned to every flagged account regardless of its
  # label -- that's what `invoices: true` means. The label itself, though, is
  # only reset when it's an exact match for the category's own key or one of its
  # translations (e.g. "Rechnungsadresse"), same as #assign_translation_match --
  # anything else is assumed to carry information beyond "this is the invoice
  # account" and is kept.
  def assign_invoices_match(accounts, category)
    exact_values = [category.key, *category.translations.filter_map(&:name)].uniq

    assign_exact_label_match(accounts, exact_values, category)
    accounts.update_all(category_id: category.id)
  end

  # For every (model, contactable_type) combination, tries in order:
  #   1. does the label match a category's own key, exactly?
  #   2. does the label contain one of a category's translated names?
  #   3. does the label match an old label from LABEL_KEY_MAPPING, exactly?
  # so a category is reachable by its own identity even if nobody ever added it to
  # LABEL_KEY_MAPPING.
  def assign_remaining_by_label
    MODELS.product(CONTACTABLES).each do |model, contactable_type|
      categories = ContactAccountCategory
        .where(contact_account_type: model.to_s, contactable_type:)
        .includes(:translations)
        .order(:position)

      accounts = model.where(contactable_type:, category_id: nil)
      assign_by_key(accounts, categories)
      assign_by_translation(accounts, categories)

      mapping = LABEL_KEY_MAPPING.dig(model.to_s, contactable_type) || {}
      assign_by_label_mapping(accounts, categories, mapping)
    end
  end

  def assign_by_key(accounts, categories)
    categories.each do |category|
      assign_exact_label_match(accounts, category.key, category)
    end
  end

  # A category name that's an exact match for the (trimmed) label, e.g. "Büro",
  # carries no information beyond "this category", so the label can be reset. A
  # partial match, where the name is embedded in something longer, e.g. "Neues
  # Büro Zürich", still identifies the category, but the label is kept, since it
  # carries more than just the category.
  TranslationMatch = Data.define(:category, :exact) do
    # nil when `label` doesn't contain `name` at all (bounded by non-alphanumeric
    # characters on both sides, via `pattern`) -- `pattern` is passed in rather
    # than built here since it's the same for every label a given category/name
    # is checked against.
    def self.for(category, pattern, name, label)
      return unless pattern.match?(label)

      new(category:, exact: label.strip.casecmp?(name))
    end

    def reset_label? = exact
  end

  def assign_by_translation(accounts, categories)
    candidates = accounts.where.not(label: [nil, ""]).pluck(:id, :label)
    return if candidates.empty?

    translation_matches(categories, candidates).each do |match, ids|
      assign_translation_match(accounts, match, ids)
    end
  end

  def assign_translation_match(accounts, match, ids)
    attrs = {category_id: match.category.id}
    attrs[:label] = nil if match.reset_label?

    accounts.where(id: ids).update_all(attrs)
  end

  def assign_by_label_mapping(accounts, categories, mapping)
    return if mapping.empty?

    category_ids = categories.index_by(&:key)

    mapping.each do |key, labels|
      category = category_ids[key.to_s]
      next unless category

      assign_exact_label_match(accounts, labels, category)
    end
  end

  def assign_remaining_other
    categories = categories_by_type(ContactAccountCategory.other)

    MODELS.product(CONTACTABLES).each do |contact_account_type, contactable_type|
      category = categories[[contact_account_type.to_s, contactable_type.to_s]]
      next unless category

      contact_account_type.where(contactable_type:, category_id: nil)
        .update_all(category_id: category.id)
    end
  end

  def assign_exact_label_match(accounts, values, category)
    by_exact_label(accounts, values).update_all(label: nil, category_id: category.id)
  end

  # `patterns` is already in priority order (categories by :position, then each
  # category's translations) -- for each candidate label, the first pattern that
  # produces a TranslationMatch wins, found lazily so later, lower-priority
  # patterns are never even checked once one matches.
  def translation_matches(categories, candidates)
    patterns = categories.flat_map { |category| translation_patterns(category) }

    ids_by_match = Hash.new { |hash, key| hash[key] = [] }

    candidates.each do |id, label|
      match = patterns.lazy
        .filter_map { |category, name, pattern|
          TranslationMatch.for(category, pattern, name, label)
        }
        .first
      ids_by_match[match] << id if match
    end

    ids_by_match
  end

  def translation_patterns(category)
    category.translations.filter_map(&:name).uniq.map do |name|
      [category, name, /(?<![[:alnum:]])#{Regexp.escape(name)}(?![[:alnum:]])/i]
    end
  end

  # Case/whitespace-insensitive exact match against one or more values, e.g. an
  # account whose (trimmed) label is "büro" or "  BÜRO  " both match "Büro".
  def by_exact_label(accounts, values)
    accounts.where("LOWER(TRIM(label)) IN (?)", Array(values).map(&:downcase))
  end

  def categories_by_type(scope)
    scope.index_by { |category| [category.contact_account_type, category.contactable_type] }
  end
end
