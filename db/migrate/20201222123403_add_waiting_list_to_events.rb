class AddWaitingListToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :waiting_list, :boolean, default: true, null: false
  end
end
