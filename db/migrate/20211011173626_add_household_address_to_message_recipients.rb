class AddHouseholdAddressToMessageRecipients < ActiveRecord::Migration[6.0]
  def change
    add_column :message_recipients, :household_address, :boolean, default: false
  end
end
