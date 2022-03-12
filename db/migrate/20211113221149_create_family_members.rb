class CreateFamilyMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :family_members do |t|
      t.belongs_to :person, null: false
      t.string :kind, null: false
      t.belongs_to :other, null: false
      t.string :family_key, null: false

      t.index :family_key
      t.index [:person_id, :other_id], unique: true
    end

    add_column :people, :family_key, :string, null: true
  end
end
