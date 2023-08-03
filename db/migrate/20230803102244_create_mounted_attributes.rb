class CreateMountedAttributes < ActiveRecord::Migration[6.1]
  def change
    create_table :mounted_attributes do |t|
      t.string :key, null: false
      t.integer :entry_id, null: false
      t.string :entry_type, null: false
      t.text :value

      t.timestamps
    end
  end
end
