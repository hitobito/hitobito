class CreateEventsGroupsAndSomeFields < ActiveRecord::Migration
  def up
    create_table :events_groups, id: false do |t|
      t.belongs_to :event
      t.belongs_to :group
    end
    
    Event.find_each do |e|
      e.group_ids = [e.group_id]
      e.save!
    end
    
    remove_column :events, :group_id
    
    add_column :events, :application_contact_id, :integer
    
    add_column :qualifications, :origin, :string
    
    add_column :people, :picture, :string
  end

  def down
    remove_column :people, :picture
    remove_column :qualifications, :origin
    remove_column :events, :application_contact_id
    
    add_column :events, :group_id, :integer
    Event.find_each do |e|
      e.group_id = e.group_ids.first
      e.save!
    end
    drop_table :events_groups
  end
end
