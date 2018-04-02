class AddAttributesToInvoice < ActiveRecord::Migration
  def change
    add_column :invoice_configs, :account_number, :string

    add_column :invoices, :account_number, :string
    add_column :invoices, :address, :text
  end
end
