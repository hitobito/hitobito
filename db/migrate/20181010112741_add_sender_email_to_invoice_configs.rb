class AddSenderEmailToInvoiceConfigs < ActiveRecord::Migration[4.2]
  def change
    add_column :invoice_configs, :email, :string
  end
end
