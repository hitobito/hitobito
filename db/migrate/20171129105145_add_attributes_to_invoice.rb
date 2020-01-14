class AddAttributesToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_configs, :account_number, :string

    add_column :invoices, :account_number, :string
    add_column :invoices, :address, :text
  end
end
