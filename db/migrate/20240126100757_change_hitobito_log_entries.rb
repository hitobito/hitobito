# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class ChangeHitobitoLogEntries < ActiveRecord::Migration[6.1]
  def up 
    change_table :hitobito_log_entries do |t|
      t.change :category, :string, null: false
      t.column :payload, :json, null: true
    end

    execute <<~SQL
      UPDATE hitobito_log_entries
      SET category = CASE
          WHEN category = 0 THEN 'webhook'
          WHEN category = 1 THEN 'ebics'
          WHEN category = 2 THEN 'mail'
          ELSE category
      END
    SQL
  end

  def down
    execute <<~SQL
        UPDATE hitobito_log_entries
        SET category = CASE
            WHEN category = 'webhook' THEN 0
            WHEN category = 'ebics' THEN 1
            WHEN category = 'mail' THEN 2
            ELSE category
        END
    SQL

    change_table :hitobito_log_entries, bulk: true do |t|
      t.change :category, :integer, null: false
      t.remove :payload
    end
  end
end
