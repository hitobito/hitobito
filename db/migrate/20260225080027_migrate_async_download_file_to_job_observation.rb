#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateAsyncDownloadFileToJobObservation < ActiveRecord::Migration[8.0]
  def change
    rename_table :async_download_files, :job_observations

    change_table :job_observations do |t|
      t.rename :name, :job_class
      t.rename :timestamp, :started_at

      t.string :filename
      t.datetime :finished_at
      t.string :status, null: false
      t.integer :attempts, null: false
      t.integer :max_attempts, null: false
      t.boolean :reports_progress, null: false
      t.datetime :last_progress_update_broadcasted_at

      t.references :delayed_job
    end

    reversible do |dir|
      dir.up do
        execute("UPDATE job_observations SET filetype = 'txt' WHERE filetype IS NULL")
        execute("UPDATE job_observations SET progress = 0 WHERE progress IS NULL")

        change_column(:job_observations, :person_id, :bigint)
        change_column(
          :job_observations, :started_at, :datetime,
          using: "to_timestamp(started_at::numeric)"
        )
      end

      dir.down do
        max_person_id = execute(
          "SELECT COALESCE(MAX(person_id), 0) as max_person_id FROM job_observations"
        ).to_a.first["max_person_id"]

        # Min and max signed integers with 4 bytes
        if (max_person_id > (-2**31)) && (max_person_id < (2**31 - 1))
          change_column(:job_observations, :person_id, :bigint)
        else
          raise "Could not rollback migration:" \
            " Changing type of column person_id on table job_observations from bigint" \
            " back to integer not possible because max person_id is outside of integer limit."
        end

        change_column(
          :job_observations, :started_at, :string,
          using: "EXTRACT(EPOCH FROM started_at)::bigint::text"
        )
      end
    end

    add_index(:job_observations, :person_id)

    change_column_null(:job_observations, :filetype, false)
    change_column_null(:job_observations, :progress, false)
  end
end
