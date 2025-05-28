# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPrivacyPolicyAcceptedAtToPeople < ActiveRecord::Migration[6.1]
  def up
    add_column :people, :privacy_policy_accepted_at, :timestamp, null: true
    add_column :groups, :privacy_policy, :string, null: true

    unless ActiveRecord::Base.connection.table_exists?('groups_translations')
      say_with_time('creating translation table for groups') do
        create_table :group_translations do |t|
          t.references :group, null: false, foreign_key: true
          t.string :locale, null: false

          t.string :privacy_policy_title

          t.timestamps
        end

        add_index :group_translations, [:group_id, :locale], unique: true
      end
    end
  end


  def down
    remove_column :people, :privacy_policy_accepted_at, :timestamp, null: true
    remove_column :groups, :privacy_policy, :string, null: true

    say_with_time('dropping translation table for groups') do
      drop_table :group_translations
    end
  end
end
