#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateAsyncDownloadFileToUserJobResult < ActiveRecord::Migration[8.0]
  def change
    rename_table :async_download_files, :user_job_results

    change_table :user_job_results do |t|
      t.rename :name, :job_class
      t.rename :timestamp, :start_timestamp

      t.string :filename
      t.datetime :end_timestamp
      t.string :status, null: false
      t.integer :attempts, null: false
      t.integer :max_attempts, null: false
      t.boolean :reports_progress, null: false
      t.datetime :last_progress_update_broadcasted_at

      t.references :delayed_job
    end

    reversible do |dir|
      dir.up do
        execute("UPDATE user_job_results SET filetype = 'txt' WHERE filetype IS NULL")
        execute("UPDATE user_job_results SET progress = 0 WHERE progress IS NULL")

        change_column(:user_job_results, :person_id, :bigint)
        change_column(
          :user_job_results, :start_timestamp, :datetime,
          using: "to_timestamp(start_timestamp::numeric)"
        )
      end

      dir.down do
        max_person_id = execute(
          "SELECT COALESCE(MAX(person_id), 0) as max_person_id FROM user_job_results"
        ).to_a.first["max_person_id"]

        # Min and max signed integers with 4 bytes
        if (max_person_id > (-2**31)) && (max_person_id < (2**31 - 1))
          change_column(:user_job_results, :person_id, :bigint)
        else
          raise "Could not rollback migration:" \
            " Changing type of column person_id on table user_job_results from bigint" \
            " back to integer not possible because max person_id is outside of integer limit."
        end

        change_column(
          :user_job_results, :start_timestamp, :string,
          using: "EXTRACT(EPOCH FROM start_timestamp)::bigint::text"
        )
      end
    end

    add_index(:user_job_results, :person_id)

    change_column_null(:user_job_results, :filetype, false)
    change_column_null(:user_job_results, :progress, false)
  end
end
