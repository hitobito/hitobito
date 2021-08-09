class AddVariableDonationAmountColumnsToInvoiceConfig < ActiveRecord::Migration[6.0]
  def change
    add_column :invoice_configs, :donation_calculation_year_amount, :integer
    add_column :invoice_configs, :donation_increase_percentage, :integer
  end
end
