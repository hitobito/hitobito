class RoundInvoices < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE invoices SET total=((round(total / 0.05)) * 0.05);"
    execute "UPDATE invoice_articles SET unit_cost=((round(unit_cost / 0.05)) * 0.05);"
    execute "UPDATE invoice_items SET unit_cost=((round(unit_cost / 0.05)) * 0.05);"
  end
end
