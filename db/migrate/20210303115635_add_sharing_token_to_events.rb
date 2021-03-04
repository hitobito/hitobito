class AddSharingTokenToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :access_token, :string, null: true
    add_index :events, :access_token, unique: true
  end
end
