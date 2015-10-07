class AddEventUserstamps < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.integer :creator_id
      t.integer :updater_id
    end
  end
end
