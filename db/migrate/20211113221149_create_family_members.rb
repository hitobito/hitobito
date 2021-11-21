class CreateFamilyMembers < ActiveRecord::Migration[6.0]
  def change
    create_table :family_members do |t|
      t.belongs_to :person
      t.string :kind
      t.belongs_to :other
      t.string :family_key
    end

    add_index :family_members, :family_key
  end
end
