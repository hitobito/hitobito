class ChangeEventContactAttrs < ActiveRecord::Migration

  def change
    change_column :events, :required_contact_attrs, :text
    change_column :events, :hidden_contact_attrs, :text
  end

end
