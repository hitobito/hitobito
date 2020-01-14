class AddCostCenterAndAccountToInvoiceItems < ActiveRecord::Migration[4.2]
  def change
    change_table(:invoice_items) do |t|
      t.string  :cost_center
      t.string  :account
    end
  end
end
