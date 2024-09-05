class CreateWebauthnCredentials < ActiveRecord::Migration[6.1]
  def change
    create_table :webauthn_credentials do |t|
      t.references :person, null: false, foreign_key: false
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname, null: false
      t.integer :sign_count, null: false, default: 0

      t.timestamps
    end
    add_index :webauthn_credentials, :external_id, unique: true
    add_index :webauthn_credentials, %i[nickname person_id], unique: true
  end
end
