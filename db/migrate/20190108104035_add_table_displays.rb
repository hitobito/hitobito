class AddTableDisplays < ActiveRecord::Migration
  def change
    create_table :table_displays do |t|
      t.string :type, null: false
      t.belongs_to :person, null: false
      t.text :selected
    end

    add_index :table_displays, [:person_id, :type], unique: true
  end
end
