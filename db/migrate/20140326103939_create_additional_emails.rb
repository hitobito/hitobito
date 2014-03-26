class CreateAdditionalEmails < ActiveRecord::Migration
  def change
    create_table :additional_emails do |t|
      t.belongs_to :contactable, polymorphic: true, null: false
      t.string :email, null: false
      t.string :label
      t.boolean :public, null: false, default: true
      t.boolean :mailings, null: false, default: true
    end
    add_index :additional_emails, [:contactable_id, :contactable_type]
  end
end
