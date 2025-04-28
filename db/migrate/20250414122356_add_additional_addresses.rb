# frozen_string_literal: true

#  Copyright (c) 2022-2025,  Eidgenössischer Jodlerverband. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


class AddAdditionalAddresses < ActiveRecord::Migration[7.1]
  def change
    create_table(:additional_addresses) do |t|
      t.belongs_to :contactable, polymorphic: true, index: true
      t.string :name, null: false
      t.string :label, null: false
      t.string :street, null: false
      t.string :housenumber, limit: 20
      t.string :zip_code, null: false
      t.string :town, null: false
      t.string :country, null: false
      t.string :address_care_of
      t.string :postbox
      t.boolean :invoices, null: false, default: false
      t.boolean :uses_contactable_name, null: false, default: true
      t.boolean :public, default: false, null: false
    end
    add_index(:additional_addresses, [:contactable_id, :contactable_type, :invoices], unique: true, where: "invoices = true")
    add_index(:additional_addresses, [:contactable_id, :contactable_type, :label], unique: true)
  end
end
