class AddPaymentForToInvoice < ActiveRecord::Migration
  def change
    add_column :invoices, :payment_for, :text
    add_column :invoice_configs, :payment_for, :text
  end
end
