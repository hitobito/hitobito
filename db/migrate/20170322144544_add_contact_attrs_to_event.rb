class AddContactAttrsToEvent < ActiveRecord::Migration[4.2]

  def change
    add_column :events, :required_contact_attrs, :string
    add_column :events, :hidden_contact_attrs, :string
  end

end
