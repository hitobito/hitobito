class AddVisibleAttributesToEvent < ActiveRecord::Migration[7.1]
  def up
    add_column :events, :visible_contact_attributes, :string, default: '["name", "address", "phone_number", "email", "social_account"]'

    execute <<-SQL.squish
      UPDATE events
      SET visible_contact_attributes = '["name", "address", "phone_number", "email", "social_account"]'
      WHERE visible_contact_attributes IS NULL
    SQL
  end

  def down
    remove_column :events, :visible_contact_attributes
  end
end
