class AddStructuredAddressesToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :recipient_name, :string
    add_column :invoices, :recipient_street, :string
    add_column :invoices, :recipient_housenumber, :string
    add_column :invoices, :recipient_zip_code, :string
    add_column :invoices, :recipient_town, :string
    add_column :invoices, :recipient_country, :string

    add_column :invoices, :payee_name, :string
    add_column :invoices, :payee_street, :string
    add_column :invoices, :payee_housenumber, :string
    add_column :invoices, :payee_zip_code, :string
    add_column :invoices, :payee_town, :string
    add_column :invoices, :payee_country, :string

    add_column :invoice_configs, :payee_name, :string
    add_column :invoice_configs, :payee_street, :string
    add_column :invoice_configs, :payee_housenumber, :string
    add_column :invoice_configs, :payee_zip_code, :string
    add_column :invoice_configs, :payee_town, :string
    add_column :invoice_configs, :payee_country, :string, default: "CH"

    InvoiceConfig.update_all(payee_country: "CH")
  end
end
