# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddHashedAttrsToBlocklistEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :blocklist_entries, :hashed_attrs, :text
    up_only do
      execute <<~SQL
        UPDATE blocklist_entries SET hashed_attrs = '["first_name","last_name","birthday"]'
      SQL
    end
    change_column_null :blocklist_entries, :hashed_attrs, false

    remove_index :blocklist_entries, :blocked_hash, unique: true
    add_index :blocklist_entries, [:blocked_hash, :hashed_attrs], unique: true
  end
end
