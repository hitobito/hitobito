class AddEventApplicationWaitingListComment < ActiveRecord::Migration
  def change
    add_column :event_applications, :waiting_list_comment, :text
  end
end
