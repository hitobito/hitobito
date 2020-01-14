class AddedCreatorToInvoice < ActiveRecord::Migration[4.2]
  def change
    remove_column :invoice_configs, :contact_id, :integer, index: true
    add_column :invoices, :creator_id, :integer, index: true
  end
end
