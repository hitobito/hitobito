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
      t.belongs_to :tag, null: false
      t.boolean :excluded, default: false
    end

    create_table :calendar_groups do |t|
      t.belongs_to :calendar, null: false
      t.belongs_to :group, null: false
      t.boolean :excluded, default: false
      t.boolean :with_subgroups, default: false
      t.string :event_type, default: nil
    end
  end
end
