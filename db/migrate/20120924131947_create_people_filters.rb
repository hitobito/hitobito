class CreatePeopleFilters < ActiveRecord::Migration
  def change
    create_table :people_filters do |t|
      t.string :name, null: false
      t.belongs_to :group
      t.string :group_type
      t.string :kind, null: false
    end
    
    create_table :people_filter_role_types do |t|
      t.belongs_to :people_filter
      t.string :role_type, null: false
    end
  end
end
