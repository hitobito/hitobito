# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetupModels < ActiveRecord::Migration[4.2]
  def change
    create_table :people do |t|
      t.string :first_name
      t.string :last_name
      t.string :company_name
      t.string :nickname
      t.boolean :company, null: false, default: false

      t.string :email

      t.string :address, limit: 1024
      t.integer :zip_code
      t.string :town
      t.string :country

      t.string :gender, limit: 1
      t.date :birthday

      t.text :additional_information

      t.boolean :contact_data_visible, null: false, default: false
      t.timestamps
    end


    create_table :groups do |t|
      t.integer :parent_id
      t.integer :lft
      t.integer :rgt

      t.string :name, null: false
      t.string :short_name, limit: 31
      t.string :type, null: false

      t.string :email
      t.string :address, limit: 1024
      t.integer :zip_code
      t.string :town
      t.string :country

      t.belongs_to :contact

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :groups, [:lft, :rgt]
    add_index :groups, :parent_id


    create_table :roles do |t|
      t.belongs_to :person, null: false
      t.belongs_to :group, null: false

      t.string :type, null: false
      t.string :label

      t.timestamps
      t.datetime :deleted_at
    end
    add_index :roles, [:person_id, :group_id]


    create_table :phone_numbers do |t|
      t.belongs_to :contactable, polymorphic: true, null: false
      t.string :number, null: false
      t.string :label
      t.boolean :public, null: false, default: true
    end
    add_index :phone_numbers, [:contactable_id, :contactable_type]


    create_table :social_accounts do |t|
      t.belongs_to :contactable, polymorphic: true, null: false
      t.string :name, null: false
      t.string :label
      t.boolean :public, null: false, default: true
    end
    add_index :social_accounts, [:contactable_id, :contactable_type]

  end
end
