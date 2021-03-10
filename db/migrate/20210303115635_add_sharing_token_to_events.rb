class AddSharingTokenToEvents < ActiveRecord::Migration[6.0]
  def change
    add_column :events, :shared_access_token, :string, null: true
    add_index :events, :shared_access_token
  end
end
