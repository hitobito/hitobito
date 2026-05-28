#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateAsyncDownloadFileToJobObservation < ActiveRecord::Migration[8.0]
  def up
    drop_table :async_download_files

    create_table :job_observations do |t|
      t.string :job_class, null: false
      t.string :filename
      t.string :filetype, null: false
      t.string :status, null: false
      t.integer :attempts, null: false
      t.integer :max_attempts, null: false
      t.integer :progress, null: false
      t.boolean :reports_progress, null: false
      t.datetime :started_at, null: false
      t.datetime :finished_at, null: false
      t.datetime :last_progress_update_broadcasted_at

      t.references :person
      t.references :delayed_job

      t.timestamps
    end
  end

  def down
    drop_table :job_observations

    create_table :async_download_files do |t|
      t.string  :name, null: false
      t.string  :filetype
      t.integer :progress
      t.integer :person_id, null: false
      t.string  :timestamp, null: false

      t.timestamps
    end
  end
end
