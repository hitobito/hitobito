class AddVisibleAttributesToEvent < ActiveRecord::Migration[7.1]
  def up
    add_column :events, :visible_contact_attributes, :string

    execute <<-SQL.squish
      UPDATE events
      SET visible_contact_attributes = '["all"]'
      WHERE visible_contact_attributes IS NULL
    SQL
  end

  def down
    remove_column :events, :visible_contact_attributes
  end
end
