# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Seeds the initial ContactAccountCategory rows derived from the previous
# config/settings.yml predefined_labels lists.
#
# Runs only once: if any ContactAccountCategory already exists, #seed is a no-op,
# so manually created categories are never touched or duplicated.
class ContactAccountCategorySeeder
  CATEGORIES = [
    # PhoneNumber
    {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "mobile",
     name: {de: "Mobil", fr: "Mobile", it: "Cellulare", en: "Mobile"}},
    {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "landline",
     name: {de: "Festnetz", fr: "Ligne fixe", it: "Telefono fisso", en: "Landline"}},
    {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "work",
     name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
    {contact_account_type: "PhoneNumber", contactable_type: "Person", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    {contact_account_type: "PhoneNumber", contactable_type: "Group", key: "office",
     name: {de: "Büro", fr: "Bureau", it: "Ufficio", en: "Office"}},
    {contact_account_type: "PhoneNumber", contactable_type: "Group", key: "mobile",
     name: {de: "Mobil", fr: "Mobile", it: "Cellulare", en: "Mobile"}},
    {contact_account_type: "PhoneNumber", contactable_type: "Group", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    # SocialAccount
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "facebook",
     name: {de: "Facebook", fr: "Facebook", it: "Facebook", en: "Facebook"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "x_twitter",
     name: {de: "X (Twitter)", fr: "X (Twitter)", it: "X (Twitter)", en: "X (Twitter)"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "website",
     unique_per_contactable: false,
     name: {de: "Webseite", fr: "Site web", it: "Sito web", en: "Website"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "linkedin",
     name: {de: "LinkedIn", fr: "LinkedIn", it: "LinkedIn", en: "LinkedIn"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "instagram",
     name: {de: "Instagram", fr: "Instagram", it: "Instagram", en: "Instagram"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "bluesky",
     name: {de: "Bluesky", fr: "Bluesky", it: "Bluesky", en: "Bluesky"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "mastodon",
     name: {de: "Mastodon", fr: "Mastodon", it: "Mastodon", en: "Mastodon"}},
    {contact_account_type: "SocialAccount", contactable_type: "Person", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "facebook",
     name: {de: "Facebook", fr: "Facebook", it: "Facebook", en: "Facebook"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "x_twitter",
     name: {de: "X (Twitter)", fr: "X (Twitter)", it: "X (Twitter)", en: "X (Twitter)"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "website",
     unique_per_contactable: false,
     name: {de: "Webseite", fr: "Site web", it: "Sito web", en: "Website"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "linkedin",
     name: {de: "LinkedIn", fr: "LinkedIn", it: "LinkedIn", en: "LinkedIn"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "instagram",
     name: {de: "Instagram", fr: "Instagram", it: "Instagram", en: "Instagram"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "bluesky",
     name: {de: "Bluesky", fr: "Bluesky", it: "Bluesky", en: "Bluesky"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "mastodon",
     name: {de: "Mastodon", fr: "Mastodon", it: "Mastodon", en: "Mastodon"}},
    {contact_account_type: "SocialAccount", contactable_type: "Group", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    # AdditionalEmail
    {contact_account_type: "AdditionalEmail", contactable_type: "Person", key: "private",
     name: {de: "Privat", fr: "Privé", it: "Privato", en: "Private"}},
    {contact_account_type: "AdditionalEmail", contactable_type: "Person", key: "work",
     name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
    {contact_account_type: "AdditionalEmail", contactable_type: "Person", key: "invoices",
     used_for_invoices: true,
     name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
            it: "Indirizzo di fatturazione", en: "Invoice"}},
    {contact_account_type: "AdditionalEmail", contactable_type: "Person", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    {contact_account_type: "AdditionalEmail", contactable_type: "Group", key: "office",
     name: {de: "Büro", fr: "Bureau", it: "Ufficio", en: "Office"}},
    {contact_account_type: "AdditionalEmail", contactable_type: "Group", key: "invoices",
     used_for_invoices: true,
     name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
            it: "Indirizzo di fatturazione", en: "Invoice"}},
    {contact_account_type: "AdditionalEmail", contactable_type: "Group", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    # AdditionalAddress
    {contact_account_type: "AdditionalAddress", contactable_type: "Person", key: "work",
     name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
    {contact_account_type: "AdditionalAddress", contactable_type: "Person", key: "invoices",
     used_for_invoices: true,
     name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
            it: "Indirizzo di fatturazione", en: "Invoice"}},
    {contact_account_type: "AdditionalAddress", contactable_type: "Person", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}},

    {contact_account_type: "AdditionalAddress", contactable_type: "Group", key: "invoices",
     used_for_invoices: true,
     name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
            it: "Indirizzo di fatturazione", en: "Invoice"}},
    {contact_account_type: "AdditionalAddress", contactable_type: "Group", key: "other",
     name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
  ].freeze

  def seed
    return if ContactAccountCategory.exists?

    ContactAccountCategory.seed_once(:contact_account_type, :contactable_type, :key, *seed_data)
  end

  private

  # Builds the flat, SeedFu-ready rows: one hash per category, with the position
  # computed per (contact_account_type, contactable_type) group and the globalized
  # name expanded into its per-locale accessors (name_de=, name_fr=, ...), since
  # SeedFu assigns attributes directly and has no notion of the current I18n.locale.
  def seed_data
    CATEGORIES
      .group_by { |attrs| [attrs[:contact_account_type], attrs[:contactable_type]] }
      .flat_map do |_group, rows|
        rows.each_with_index.map { |attrs, position| row_for(attrs, position) }
      end
  end

  def row_for(attrs, position)
    {
      contact_account_type: attrs.fetch(:contact_account_type),
      contactable_type: attrs.fetch(:contactable_type),
      key: attrs.fetch(:key),
      unique_per_contactable: attrs.fetch(:unique_per_contactable, attrs.fetch(:key) != "other"),
      used_for_invoices: attrs.fetch(:used_for_invoices, false),
      position: position
    }.merge(localized_names(attrs.fetch(:name)))
  end

  def localized_names(names)
    Settings.application.languages.keys.to_h do |locale|
      [:"name_#{locale}", names[locale.to_sym] || names.fetch(:de)]
    end
  end
end
