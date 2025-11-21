class RenameInvoiceListsToInvoiceRuns < ActiveRecord::Migration[8.0]
  def change
    rename_table(:invoice_lists, :invoice_runs)
    rename_column(:invoices, :invoice_list_id, :invoice_run_id)
    rename_column(:messages, :invoice_list_id, :invoice_run_id)
  end
end
