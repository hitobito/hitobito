#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateAsyncDownloadFileToUserJobResult < ActiveRecord::Migration[8.0]
  def change
    rename_table :async_download_files, :user_job_results
    change_table :user_job_results do |t|
      t.rename :name, :job_name
      t.rename :timestamp, :start_timestamp

      t.string :filename
      t.datetime :end_timestamp
      t.string :status, null: false, default: :planned
      t.integer :attempts, null: false, default: 0
      t.integer :max_attempts, null: false
      t.boolean :reports_progress, default: false, null: false
    end

    reversible do |dir|
      dir.up do
        execute("UPDATE user_job_results SET filetype = 'txt' WHERE filetype IS NULL")
        execute("UPDATE user_job_results SET progress = 0 WHERE progress IS NULL")

        change_column(
          :user_job_results, :start_timestamp, :datetime,
          using: "to_timestamp(start_timestamp::numeric)"
        )
      end

      dir.down do
        change_column(
          :user_job_results, :start_timestamp, :string,
          using: "EXTRACT(EPOCH FROM start_timestamp)::bigint::text"
        )
      end
    end

    change_column_null(:user_job_results, :filetype, false)
    change_column_null(:user_job_results, :progress, false)

    change_column_default(:user_job_results, :filetype, from: nil, to: "txt")
    change_column_default(:user_job_results, :progress, from: nil, to: 0)
    change_column_default(:user_job_results, :start_timestamp, from: nil, to: -> { "CURRENT_TIMESTAMP" })
  end
end
