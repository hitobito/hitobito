#  Copyright (c) 2012-2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateAsyncDownloadFileToUserJobResult < ActiveRecord::Migration[8.0]
  def change
    rename_table :async_download_files, :user_job_results
    change_table :user_job_results do |t|
      t.string :filename
      t.rename :timestamp, :start_timestamp
      t.string :end_timestamp
      t.string :status
      t.integer :attempts
      t.references :delayed_job, foreign_key: false
      t.boolean :reports_progress, default: false, null: false
    end
  end
end
