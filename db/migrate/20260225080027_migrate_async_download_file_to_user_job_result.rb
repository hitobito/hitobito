class MigrateAsyncDownloadFileToUserJobResult < ActiveRecord::Migration[8.0]
  def change
    rename_table :async_download_files, :user_job_results
    change_table :user_job_results do |t|
      t.rename :timestamp, :start_timestamp
      t.datetime :end_timestamp
      t.string :status
    end
    add_reference :user_job_results, :delayed_job
  end
end
