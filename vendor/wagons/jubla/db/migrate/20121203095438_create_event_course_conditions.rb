class CreateEventCourseConditions < ActiveRecord::Migration
  def change
    create_table :event_conditions do |t|
      t.integer :group_id
      t.string :label, null: false
      t.text :content, null: false

      t.timestamps
    end

    add_index :event_conditions, [:group_id, :label], :unique => true
    add_column :events, :condition_id, :integer
  end
end
