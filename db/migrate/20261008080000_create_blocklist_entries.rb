# frozen_string_literal: true

#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateBlocklistEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :blocklist_entries do |t|
      t.string :blocked_hash, null: false, index: {unique: true}
      t.bigint :creator_id, index: true
      t.datetime :created_at, null: false
    end
  end
end
