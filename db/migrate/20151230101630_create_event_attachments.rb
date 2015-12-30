class CreateEventAttachments < ActiveRecord::Migration
  def change
    create_table :event_attachments do |t|
      t.belongs_to :event, null: false
      t.string :file, null: false
    end

    add_index :event_attachments, :event_id
  end
end
