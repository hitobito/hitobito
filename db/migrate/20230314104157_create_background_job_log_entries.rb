# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateBackgroundJobLogEntries < ActiveRecord::Migration[6.1]
  def up
    create_table :background_job_log_entries do |t|
      t.bigint :job_id, null: false, index: true
      t.string :job_name, null: false, index: true
      t.references :group
      t.datetime :started_at, precision: 6
      t.datetime :finished_at, precision: 6
      t.integer :attempt
      t.string :status
      t.json :payload

      t.index [:job_id, :attempt], unique: true
    end

    # execute <<-SQL
    #   ALTER TABLE background_job_log_entries
    #   ADD COLUMN runtime INTEGER GENERATED ALWAYS AS (
    #     CASE
    #       WHEN finished_at IS NOT NULL AND started_at IS NOT NULL
    #       THEN EXTRACT(EPOCH FROM finished_at - started_at) * 1000000
    #       ELSE NULL
    #     END
    #   ) STORED;
    # SQL
  end

  def down
    drop_table :background_job_log_entries
  end
end
