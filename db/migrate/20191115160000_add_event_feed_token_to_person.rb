class AddEventFeedTokenToPerson < ActiveRecord::Migration
  def change
    add_column :people, :event_feed_token, :string, null: true
  end
end
