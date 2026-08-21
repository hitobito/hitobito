# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ContactAccountCategoryMigrationJob < BaseJob
  self.parameters = []

  USED_FOR_INVOICES_MODELS = [AdditionalAddress, AdditionalEmail].product(%w[Person Group]).freeze
  MODELS = [PhoneNumber, SocialAccount, AdditionalEmail, AdditionalAddress].freeze

  # Maps an old free-text labels to the ContactAccountCategory#key, wagons might extend
  LABEL_KEY_MAPPING = {
    ["PhoneNumber", "Person"] => {"privat" => "landline", "mobil" => "mobile", "arbeit" => "work"},
    ["PhoneNumber", "Group"] => {"arbeit" => "office", "mobil" => "mobile", "andere" => "other"},
    ["SocialAccount", "Person"] => {"facebook" => "facebook", "twitter" => "x_twitter",
                                    "webseite" => "website", "andere" => "other"},
    ["SocialAccount", "Group"] => {"facebook" => "facebook", "twitter" => "x_twitter",
                                   "webseite" => "website", "andere" => "other"},
    ["AdditionalEmail", "Person"] => {"privat" => "private", "arbeit" => "work",
                                      "andere" => "other"},
    ["AdditionalEmail", "Group"] => {"arbeit" => "office", "andere" => "other"},
    ["AdditionalAddress", "Person"] => {"arbeit" => "work"}
  }

  def perform
    assign_used_for_invoices
    assign_remaining_by_label
    assign_remaining_other
  end

  private

  def assign_used_for_invoices
    category_ids = build_categories_hash(ContactAccountCategory.used_for_invoices)

    USED_FOR_INVOICES_MODELS.each do |contact_account_type, contactable_type|
      category_id = category_ids.dig(contact_account_type.to_s, contactable_type.to_s)
      next unless category_id

      accounts = contact_account_type.where(contactable_type:, category_id: nil, invoices: true)
      accounts.update_all(category_id:, label: nil)
    end
  end

  def assign_remaining_by_label
    LABEL_KEY_MAPPING.each do |(contact_account_type, contactable_type), mapping|
      category_ids = ContactAccountCategory
        .where(contact_account_type:, contactable_type:).pluck(:key, :id).to_h
      accounts = contact_account_type.constantize.where(contactable_type:, category_id: nil)

      mapping.each do |label, key|
        category_id = category_ids[key]
        next unless category_id

        accounts.where("LOWER(TRIM(label)) = ?", label).update_all(label: nil, category_id:)
      end
    end
  end

  def assign_remaining_other
    category_ids = build_categories_hash(ContactAccountCategory.other)

    MODELS.product(%w[Person Group]).each do |contact_account_type, contactable_type|
      category_id = category_ids.dig(contact_account_type.to_s, contactable_type.to_s)
      next unless category_id

      contact_account_type.where(contactable_type:, category_id: nil).update_all(category_id:)
    end
  end

  def build_categories_hash(categories_scope)
    categories_scope
      .pluck(:contact_account_type, :contactable_type, :id)
      .group_by(&:shift)
      .transform_values(&:to_h)
  end
end
