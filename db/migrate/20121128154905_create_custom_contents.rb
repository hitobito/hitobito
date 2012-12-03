class CreateCustomContents < ActiveRecord::Migration
  def change
    create_table :custom_contents do |t|
      t.string :key, null: false, unique: true
      t.string :label, null: false, unique: true
      t.string :subject
      t.text :body
      t.string :placeholders_required
      t.string :placeholders_optional
    end
  end
end
