class AddContactAttrsToEvent < ActiveRecord::Migration

  def change
    add_column :events, :required_contact_attrs, :string
    add_column :events, :hidden_contact_attrs, :string
  end

end
