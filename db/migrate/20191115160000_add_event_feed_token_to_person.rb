class AddEventFeedTokenToPerson < ActiveRecord::Migration
  def change
    add_column :people, :event_feed_token, :string, null: true
    add_index :people, :event_feed_token, unique: true
  end
end
