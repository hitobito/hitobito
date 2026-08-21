# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Seeds the ContactAccountCategory rows derived from the previous
# config/settings.yml predefined_labels lists. #seed is idempotent per row
# (via seed_once), so it can run again on every deploy to pick up categories
# added by a later release without touching or duplicating existing ones.
#
# ContactAccountCategoryMigrationJob is only run the very first time #seed
# runs (i.e. when the table was completely empty beforehand), so the one-time
# backfill never re-runs on an already-migrated install. Run synchronously
# rather than enqueued -- #seed is called from a migration (see
# db/migrate/*_seed_and_backfill_contact_account_categories.rb), so the
# backfill is guaranteed to have finished before a new release starts serving
# traffic, instead of racing an async job against the deploy.
class ContactAccountCategorySeeder
  # Nested as contact_account_type => contactable_type => [{key:, name:, ...}],
  # so all the categories for one combination -- and their relative
  # order/position -- are readable together. Wagons extend this by digging
  # into (or building) the nested structure directly, e.g.:
  #   ContactAccountCategorySeeder::CATEGORIES["PhoneNumber"]["Person"] <<
  #     {key: "natel", name: {de: "Natel", fr: "Natel", it: "Natel", en: "Mobile"}}
  CATEGORIES = {
    "PhoneNumber" => {
      "Person" => [
        {key: "mobile", name: {de: "Mobil", fr: "Mobile", it: "Cellulare", en: "Mobile"}},
        {key: "landline",
         name: {de: "Festnetz", fr: "Ligne fixe", it: "Telefono fisso", en: "Landline"}},
        {key: "work", name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ],
      "Group" => [
        {key: "office", name: {de: "Büro", fr: "Bureau", it: "Ufficio", en: "Office"}},
        {key: "mobile", name: {de: "Mobil", fr: "Mobile", it: "Cellulare", en: "Mobile"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ]
    },
    "SocialAccount" => {
      "Person" => [
        {key: "facebook", name: {de: "Facebook", fr: "Facebook", it: "Facebook", en: "Facebook"}},
        {key: "x_twitter",
         name: {de: "X (Twitter)", fr: "X (Twitter)", it: "X (Twitter)", en: "X (Twitter)"}},
        {key: "website", unique_per_contactable: false,
         name: {de: "Webseite", fr: "Site web", it: "Sito web", en: "Website"}},
        {key: "linkedin", name: {de: "LinkedIn", fr: "LinkedIn", it: "LinkedIn", en: "LinkedIn"}},
        {key: "instagram",
         name: {de: "Instagram", fr: "Instagram", it: "Instagram", en: "Instagram"}},
        {key: "bluesky", name: {de: "Bluesky", fr: "Bluesky", it: "Bluesky", en: "Bluesky"}},
        {key: "mastodon", name: {de: "Mastodon", fr: "Mastodon", it: "Mastodon", en: "Mastodon"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ],
      "Group" => [
        {key: "facebook", name: {de: "Facebook", fr: "Facebook", it: "Facebook", en: "Facebook"}},
        {key: "x_twitter",
         name: {de: "X (Twitter)", fr: "X (Twitter)", it: "X (Twitter)", en: "X (Twitter)"}},
        {key: "website", unique_per_contactable: false,
         name: {de: "Webseite", fr: "Site web", it: "Sito web", en: "Website"}},
        {key: "linkedin", name: {de: "LinkedIn", fr: "LinkedIn", it: "LinkedIn", en: "LinkedIn"}},
        {key: "instagram",
         name: {de: "Instagram", fr: "Instagram", it: "Instagram", en: "Instagram"}},
        {key: "bluesky", name: {de: "Bluesky", fr: "Bluesky", it: "Bluesky", en: "Bluesky"}},
        {key: "mastodon", name: {de: "Mastodon", fr: "Mastodon", it: "Mastodon", en: "Mastodon"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ]
    },
    "AdditionalEmail" => {
      "Person" => [
        {key: "private", name: {de: "Privat", fr: "Privé", it: "Privato", en: "Private"}},
        {key: "work", name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
        {key: "invoices", used_for_invoices: true,
         name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
                it: "Indirizzo di fatturazione", en: "Invoice"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ],
      "Group" => [
        {key: "office", name: {de: "Büro", fr: "Bureau", it: "Ufficio", en: "Office"}},
        {key: "invoices", used_for_invoices: true,
         name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
                it: "Indirizzo di fatturazione", en: "Invoice"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ]
    },
    "AdditionalAddress" => {
      "Person" => [
        {key: "work", name: {de: "Arbeit", fr: "Professionnel", it: "Ufficio", en: "Work"}},
        {key: "invoices", used_for_invoices: true,
         name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
                it: "Indirizzo di fatturazione", en: "Invoice"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ],
      "Group" => [
        {key: "invoices", used_for_invoices: true,
         name: {de: "Rechnungsadresse", fr: "Adresse de facturation",
                it: "Indirizzo di fatturazione", en: "Invoice"}},
        {key: "other", name: {de: "Andere", fr: "Autre", it: "Altro", en: "Other"}}
      ]
    }
  }

  def self.category_count
    CATEGORIES.sum { |_contact_account_type, by_contactable_type|
      by_contactable_type.sum { |_contactable_type, rows| rows.size }
    }
  end

  def seed
    first_time = ContactAccountCategory.none?
    ContactAccountCategory.seed_once(:contact_account_type, :contactable_type, :key, *seed_data)
    ContactAccountCategoryMigrationJob.new.perform if first_time
  end

  private

  def seed_data
    CATEGORIES.flat_map do |contact_account_type, by_contactable_type|
      by_contactable_type.flat_map do |contactable_type, rows|
        rows.each_with_index.map do |attrs, position|
          row_for(contact_account_type, contactable_type, attrs, position)
        end
      end
    end
  end

  def row_for(contact_account_type, contactable_type, attrs, position)
    {
      contact_account_type: contact_account_type,
      contactable_type: contactable_type,
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
