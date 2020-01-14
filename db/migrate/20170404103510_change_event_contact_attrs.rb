class ChangeEventContactAttrs < ActiveRecord::Migration[4.2]

  def change
    change_column :events, :required_contact_attrs, :text
    change_column :events, :hidden_contact_attrs, :text
  end

end
