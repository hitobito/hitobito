class AddGuestLimitToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :guest_limit, :integer, null: false, default: 0
  end
end
