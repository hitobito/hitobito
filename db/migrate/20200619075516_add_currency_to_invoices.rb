class AddCurrencyToInvoices < ActiveRecord::Migration[6.0]
  def change
    add_column(:invoice_configs, :currency, :string, default: 'CHF', null: false)
    add_column(:invoices, :currency, :string, default: 'CHF', null: false)

    reversible do |dir|
      dir.up do
        execute "UPDATE invoices SET currency = '#{Settings.currency.unit}'"
        execute "UPDATE invoice_configs SET currency = '#{Settings.currency.unit}'"
      end
    end
  end
end
