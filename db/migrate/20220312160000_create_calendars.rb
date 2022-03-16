class CreateCalendars < ActiveRecord::Migration[6.1]
  def change
    create_table :calendars do |t|
      t.string :name, null: false
      t.belongs_to :group, null: false
      t.text :description
      t.string :token, null: false
    end

    create_table :calendar_tags do |t|
      t.belongs_to :calendar, null: false
      t.integer :tag_id, null: false
      t.boolean :excluded, default: false
    end

    # Necessary to auto-delete calendar_tags when the corresponding tag is deleted
    add_foreign_key :calendar_tags, :tags, on_delete: :cascade

    create_table :calendar_groups do |t|
      t.belongs_to :calendar, null: false
      t.belongs_to :group, null: false
      t.boolean :excluded, default: false
      t.boolean :with_subgroups, default: false
      t.string :event_type, default: nil
    end
  end
end
