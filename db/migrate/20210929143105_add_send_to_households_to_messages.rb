class AddSendToHouseholdsToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :send_to_households, :boolean, default: false, null: false
  end
end
