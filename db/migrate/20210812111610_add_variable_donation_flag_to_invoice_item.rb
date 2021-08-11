class AddVariableDonationFlagToInvoiceItem < ActiveRecord::Migration[6.0]
  def change
    add_column :invoice_items, :variable_donation, :boolean, null: false, default: false
  end
end
