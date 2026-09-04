# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddContactAccountCategories < ActiveRecord::Migration[8.0]
  CONTACT_ACCOUNT_TABLES = [:additional_addresses, :additional_emails, :phone_numbers,
    :social_accounts]

  def up
    create_categories_table
    add_category_references
    make_additional_address_label_freetext
    seed_and_backfill_categories
    make_category_not_nullable
  end

  def down
    CONTACT_ACCOUNT_TABLES.each { |table| change_column_null table, :category_id, true }

    backfill_contact_account_labels
    backfill_additional_address_labels
    change_column_null :additional_addresses, :label, false
    add_index :additional_addresses, [:contactable_id, :contactable_type, :label], unique: true, if_not_exists: true

    CONTACT_ACCOUNT_TABLES.each { |table| remove_reference table, :category, index: true }

    ContactAccountCategory.drop_translation_table!
    drop_table :contact_account_categories
  end

  private

  def create_categories_table
    create_table :contact_account_categories do |t|
      t.string :key, null: false
      t.string :contact_account_type, null: false
      t.string :contactable_type, null: false
      t.boolean :unique_per_contactable, null: false, default: false
      t.boolean :used_for_invoices, null: false, default: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :contact_account_categories, [:contact_account_type, :contactable_type, :key],
      unique: true, name: "index_contact_account_categories_on_type_and_key"

    ContactAccountCategory.create_translation_table! name: {type: :string, null: false}

    ContactAccountCategory.reset_column_information
    ContactAccountCategory::Translation.reset_column_information
  end

  def add_category_references
    CONTACT_ACCOUNT_TABLES.each do |table|
      add_reference table, :category, index: true, foreign_key: false
    end

    [AdditionalAddress, AdditionalEmail, PhoneNumber, SocialAccount].each(&:reset_column_information)
  end

  def make_additional_address_label_freetext
    remove_index :additional_addresses, column: [:contactable_id, :contactable_type, :label], if_exists: true
    change_column_null :additional_addresses, :label, true
  end

  def backfill_contact_account_labels
    (CONTACT_ACCOUNT_TABLES - [:additional_addresses]).each do |table|
      execute(<<~SQL)
        UPDATE #{table}
        SET label = COALESCE(
          NULLIF(TRIM(#{table}.label), ''),
          contact_account_category_translations.name,
          contact_account_categories.key
        )
        FROM contact_account_categories
        LEFT JOIN contact_account_category_translations
          ON contact_account_category_translations.contact_account_category_id = contact_account_categories.id
          AND contact_account_category_translations.locale = 'de'
        WHERE #{table}.category_id = contact_account_categories.id
      SQL
    end
  end

  def backfill_additional_address_labels
    execute(<<~SQL)
      UPDATE additional_addresses
      SET label = (
        COALESCE(
          NULLIF(TRIM(additional_addresses.label), ''),
          contact_account_category_translations.name,
          contact_account_categories.key
        ) || '-' || additional_addresses.id
      )
      FROM contact_account_categories
      LEFT JOIN contact_account_category_translations
        ON contact_account_category_translations.contact_account_category_id = contact_account_categories.id
        AND contact_account_category_translations.locale = 'de'
      WHERE additional_addresses.category_id = contact_account_categories.id
    SQL
  end

  def seed_and_backfill_categories
    require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")
    ContactAccountCategorySeeder.new.seed
  end

  def make_category_not_nullable
    CONTACT_ACCOUNT_TABLES.each { |table| change_column_null table, :category_id, false }
  end
end
