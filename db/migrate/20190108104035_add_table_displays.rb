class AddTableDisplays < ActiveRecord::Migration
  def change
    create_table :table_displays do |t|
      t.belongs_to :person, null: false
      t.belongs_to :parent, polymorphic: true, null: false
      t.text :selected
    end

    add_index :table_displays, [:person_id, :parent_id, :parent_type], unique: true
  end
end
