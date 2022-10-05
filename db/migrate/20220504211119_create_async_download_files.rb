class CreateAsyncDownloadFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :async_download_files do |t|
      t.string  :name,      null: false
      t.string  :filetype
      t.integer :progress
      t.integer :person_id, null: false
      t.string  :timestamp, null: false

      t.timestamps
    end
  end
end
