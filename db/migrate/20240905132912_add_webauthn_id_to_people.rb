class AddWebauthnIdToPeople < ActiveRecord::Migration[6.1]
  def change
    add_column :people, :webauthn_id, :string
    add_index :people, :webauthn_id, unique: true
  end
end
