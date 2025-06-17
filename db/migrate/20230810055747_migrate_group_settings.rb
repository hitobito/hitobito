# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateGroupSettings < ActiveRecord::Migration[6.1]
  def up
    say_with_time('create group attributes') do
      add_column :groups, :encrypted_text_message_username, :string
      add_column :groups, :encrypted_text_message_password, :string
      add_column :groups, :text_message_provider, :string, null: false, default: 'aspsms'
      add_column :groups, :text_message_originator, :string
      add_column :groups, :letter_address_position, :string, null: false, default: 'left'
      add_column :groups, :letter_logo, :string
    end

    drop_table :settings
  end

  def down
    create_table "sessions" do |t|
      t.string "session_id", null: false
      t.text "data"
      t.bigint "person_id"
      t.index "person_id"
      t.index "session_id"
      t.index "updated_at"

      t.timestamps
    end

    say_with_time('remove group attributes') do
      remove_column :groups, :encrypted_text_message_username
      remove_column :groups, :encrypted_text_message_password
      remove_column :groups, :text_message_provider
      remove_column :groups, :text_message_originator
      remove_column :groups, :letter_address_position
      remove_column :groups, :letter_logo
    end
  end
end
