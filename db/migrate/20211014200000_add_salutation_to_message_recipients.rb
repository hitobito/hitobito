class AddSalutationToMessageRecipients < ActiveRecord::Migration[6.0]
  def change
    remove_column :message_recipients, :household_address
    add_column :message_recipients, :salutation, :string, default: ''
  end
end
