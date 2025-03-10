class AddReferencePrefixToInvoiceConfigs < ActiveRecord::Migration[7.1]
  def change
    add_column :invoice_configs, :reference_prefix, :integer
  end
end
