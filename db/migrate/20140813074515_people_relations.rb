class PeopleRelations < ActiveRecord::Migration
  def change
    create_table :people_relations do |t|
      t.integer :head_id, null: false
      t.integer :tail_id, null: false
      t.string :kind, null: false
    end

    add_index :people_relations, :head_id
    add_index :people_relations, :tail_id
  end
end
