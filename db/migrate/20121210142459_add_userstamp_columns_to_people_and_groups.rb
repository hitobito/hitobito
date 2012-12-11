class AddUserstampColumnsToPeopleAndGroups < ActiveRecord::Migration
  def change

    change_table :groups do |t|
      t.integer :creator_id
      t.integer :updater_id
      t.integer :deleter_id
    end

    change_table :people do |t|
      t.integer :creator_id
      t.integer :updater_id
    end

  end
end
