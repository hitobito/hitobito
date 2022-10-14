# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class CreateHitobitoLogEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :hitobito_log_entries do |t|
      t.timestamps
      t.integer :category, null: false, index: true
      t.integer :level, null: false, index: true
      t.text :message, null: false
      t.references :subject, polymorphic: true
    end
  end
end
