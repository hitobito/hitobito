class AddEventColumns < ActiveRecord::Migration
  def change
    add_column :events, :participant_count, :integer, default: 0
    change_column :events, :type, :string, null: true
  end
end
