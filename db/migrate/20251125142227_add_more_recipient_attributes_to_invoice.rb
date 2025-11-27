class AddMoreRecipientAttributesToInvoice < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :recipient_company_name, :string
    add_column :invoices, :recipient_address_care_of, :string
    add_column :invoices, :recipient_postbox, :string

    rename_column :invoices, :payee, :deprecated_payee
    rename_column :invoices, :recipient_address, :deprecated_recipient_address
  end
end
