class RenamedPaymentForToPayee < ActiveRecord::Migration[4.2]
  def change
    rename_column :invoices, :payment_for, :payee
    rename_column :invoice_configs, :payment_for, :payee
  end
end
