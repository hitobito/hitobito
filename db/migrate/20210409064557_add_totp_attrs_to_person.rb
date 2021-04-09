class AddTotpAttrsToPerson < ActiveRecord::Migration[6.0]
  def change
    add_column :people, :second_factor_auth, :integer, default: 0, null: false
    add_column :people, :encrypted_totp_secret, :text, limit: 300, null: true
  end
end
