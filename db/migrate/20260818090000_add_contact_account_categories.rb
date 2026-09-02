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

    change_column_null :additional_addresses, :label, false
    add_index :additional_addresses, [:contactable_id, :contactable_type, :label], unique: true

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
  end

  def add_category_references
    CONTACT_ACCOUNT_TABLES.each do |table|
      add_reference table, :category, index: true, foreign_key: false
    end
  end

  def make_additional_address_label_freetext
    remove_index :additional_addresses, column: [:contactable_id, :contactable_type, :label]
    change_column_null :additional_addresses, :label, true
  end

  def seed_and_backfill_categories
    return if Rails.env.test? # categories are provided via fixtures in tests

    require Rails.root.join("db", "seeds", "support", "contact_account_category_seeder")
    ContactAccountCategorySeeder.new.seed
  end

  def make_category_not_nullable
    CONTACT_ACCOUNT_TABLES.each { |table| change_column_null table, :category_id, false }
  end
end
