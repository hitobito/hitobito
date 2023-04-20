# frozen_string_literal: true

#  Copyright (c) 2023, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateBackgroundJobLogEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :background_job_log_entries do |t|
      t.bigint :job_id, null: false, index: true
      t.string :job_name, null: false, index: true
      t.references :group
      t.datetime :started_at, precision: 6
      t.datetime :finished_at, precision: 6
      t.virtual :runtime, type: :integer, as: "TIMESTAMPDIFF(MICROSECOND, started_at, finished_at)"
      t.integer :attempt
      t.string :status
      t.json :payload

      t.index [:job_id, :attempt], unique: true
    end
  end
end
