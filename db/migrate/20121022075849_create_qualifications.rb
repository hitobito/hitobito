class CreateQualifications < ActiveRecord::Migration
  def change
    create_table :qualification_types do |t|
      t.string :label, null: false
      t.integer :validity
      t.string :description, limit: 1023
      
      t.timestamps
      t.datetime :deleted_at
    end
    
    create_table :qualifications do |t|
      t.belongs_to :person, null: false
      t.belongs_to :qualification_type, null: false
      
      t.date :start_at, null: false
      t.date :finish_at
    end
    
    create_table :event_kinds_preconditions do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_type, null: false
    end
    
    create_table :event_kinds_qualification_types do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_type, null: false
    end
    
    create_table :event_kinds_prolongations do |t|
      t.belongs_to :event_kind, null: false
      t.belongs_to :qualification_type, null: false
    end
    
    add_column :event_kinds, :minimum_age, :integer
  end
end
