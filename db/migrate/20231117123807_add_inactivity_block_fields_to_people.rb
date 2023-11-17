class AddInactivityBlockFieldsToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :inactivity_block_warning_sent_at, :datetime, null: true
    add_column :people, :blocked_at, :datetime, null: true
  end
end
