class RenameInvoiceListsToInvoiceRuns < ActiveRecord::Migration[8.0]
  def change
    # Since the table was initially created with mysql the pkey index does not follow the naming convention the postgres adapter expects.
    # Thus we rename it beforehand
    rename_index(:invoice_lists, find_pkey_index_name, :invoice_lists_pkey)

    rename_table(:invoice_lists, :invoice_runs)
    rename_column(:invoices, :invoice_list_id, :invoice_run_id)
    rename_column(:messages, :invoice_list_id, :invoice_run_id)
  end

  def find_pkey_index_name
    result = execute <<~SQL
      SELECT
        i.relname AS primary_key_index_name
      FROM
        pg_constraint c
      JOIN
        pg_class t ON c.conrelid = t.oid
      JOIN
        pg_class i ON c.conindid = i.oid
      WHERE
        t.relname = 'invoice_lists'
        AND c.contype = 'p'
        AND t.relkind = 'r' -- 'r' for regular table
        AND t.relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');
    SQL
    result.first["primary_key_index_name"]
  end
end
