class DropCarrierwaveColumns < ActiveRecord::Migration[6.1]
  def change
    remove_column :groups, :logo, :string
    remove_column :groups, :letter_logo, :string
    remove_column :oauth_applications, :logo, :string
    remove_column :people, :picture, :string
    remove_column :event_attachments, :file, :string
  end
end
