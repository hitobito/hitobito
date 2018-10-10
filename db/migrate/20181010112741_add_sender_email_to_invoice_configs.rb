class AddSenderEmailToInvoiceConfigs < ActiveRecord::Migration
  def change
    add_column :invoice_configs, :email, :string
  end
end
