# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class CreatePassesTables < ActiveRecord::Migration[8.0]
  def change
    create_table :pass_definitions do |t|
      t.references :owner, polymorphic: true, null: false
      t.string :template_key, default: "default", null: false
      t.string :background_color, default: "#ffffff", null: false
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        PassDefinition.create_translation_table!(
          name: :string,
          description: :text
        )
      end

      dir.down do
        PassDefinition.drop_translation_table!
      end
    end

    create_table :pass_grants do |t|
      t.references :pass_definition, null: false, index: false
      t.references :grantor, polymorphic: true, null: false, index: false
      t.timestamps
    end

    add_index :pass_grants, [:pass_definition_id, :grantor_type, :grantor_id],
      unique: true, name: "idx_pass_grants_unique"

    create_table :passes do |t|
      t.references :person, null: false, index: false
      t.references :pass_definition, null: false, index: false
      t.string :state, default: "eligible", null: false
      t.date :valid_from, null: false
      t.date :valid_until
      t.timestamps
    end

    add_index :passes, [:person_id, :pass_definition_id],
      unique: true, name: "idx_passes_unique"

    create_table :wallets_pass_installations do |t|
      t.references :pass, null: false, index: false
      t.integer :wallet_type, null: false
      t.integer :state, default: 0, null: false
      t.string :locale, null: false
      t.string :authentication_token
      t.datetime :last_synced_at
      t.text :sync_error
      t.boolean :needs_sync, default: false, null: false
      t.timestamps
    end

    add_index :wallets_pass_installations, [:pass_id, :wallet_type],
      unique: true, name: "idx_wallets_pass_installations_unique"
    add_index :wallets_pass_installations, :needs_sync,
      name: "idx_wallets_pass_installations_needs_sync"

    create_table :wallets_apple_device_registrations do |t|
      t.references :pass_installation, null: false, index: false
      t.string :device_library_identifier, null: false
      t.string :push_token, null: false
      t.timestamps
    end

    add_index :wallets_apple_device_registrations,
      [:device_library_identifier, :pass_installation_id],
      unique: true, name: "idx_wallets_apple_device_reg_unique"
  end
end
