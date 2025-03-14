class CreateHours < ActiveRecord::Migration[7.0]
  def change
    create_table :hours do |t|
      t.integer :person_id
      t.integer :event_id
      t.string :custom_item
      t.string :custom_item_date
      t.integer :volunteer_hours
      t.boolean :submitted_status
      t.boolean :approved_status
      t.timestamps
    end
  end
end
