class AddAuthenticationTokenToPeople < ActiveRecord::Migration
  def change
    add_column :people, :authentication_token, :string
    add_index :people, :authentication_token
  end
end
