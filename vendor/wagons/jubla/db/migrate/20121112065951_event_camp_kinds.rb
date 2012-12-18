class EventCampKinds < ActiveRecord::Migration

  def change
    create_table :event_camp_kinds do |t|
      t.string :label
      t.timestamps
      t.datetime :deleted_at
    end
  end
  
end
