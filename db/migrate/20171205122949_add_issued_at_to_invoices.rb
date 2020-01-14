class AddIssuedAtToInvoices < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :issued_at, :date
  end
end
