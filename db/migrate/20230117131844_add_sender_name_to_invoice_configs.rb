class AddSenderNameToInvoiceConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :invoice_configs, :sender_name, :string
  end
end
