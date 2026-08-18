# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateContactAccountCategories < ActiveRecord::Migration[8.0]
  def up
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

  def down
    ContactAccountCategory.drop_translation_table!
    drop_table :contact_account_categories
  end
end
