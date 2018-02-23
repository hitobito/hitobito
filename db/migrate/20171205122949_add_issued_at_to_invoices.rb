class AddIssuedAtToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :issued_at, :date
  end
end
