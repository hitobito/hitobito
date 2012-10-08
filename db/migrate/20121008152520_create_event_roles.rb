class CreateEventRoles < ActiveRecord::Migration
  def up
    create_table :event_roles do |t|
      t.string :type, null: false
      t.belongs_to :participation, null: false
      t.string :label
    end
    
    remove_column :event_participations, :type
    remove_column :event_participations, :label
    add_column :event_participations, :active, :boolean, null: false, default: false
    add_column :event_participations, :application_id, :integer
    change_column :event_participations, :event_id, :integer, null: false
    
    remove_column :event_applications, :participation_id
    
    Event::Participation.destroy_all
    add_index :event_participations, [:event_id, :person_id], unique: true
  end
  
  def down
    remove_index :event_participations, [:event_id, :person_id]
    
    remove_column :event_participations, :active
    remove_column :event_participations, :application_id
    add_column :event_participations, :type, :string
    add_column :event_participations, :label, :string
    
    add_column :event_applications, :participation_id, :integer
    
    drop_table :event_roles
  end
end
