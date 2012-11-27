class CreateLabelFormats < ActiveRecord::Migration
  def change
    create_table :label_formats do |t|
      t.string :name, null: false, unique: true
      t.string :page_size, null: false, default: 'A4'
      t.boolean :landscape, null: false, default: false
      t.float :font_size, null: false, default: 11
      t.float :width, null: false
      t.float :height, null: false
      t.integer :count_horizontal, null: false
      t.integer :count_vertical, null: false
      t.float :padding_top, null: false
      t.float :padding_left, null: false
    end
    
    add_column :people, :last_label_format_id, :integer
    
    add_index :roles, :type
  end
end
