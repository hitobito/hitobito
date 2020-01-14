class AddPaymentForToInvoice < ActiveRecord::Migration[4.2]
  def change
    add_column :invoices, :payment_for, :text
    add_column :invoice_configs, :payment_for, :text
  end
end
