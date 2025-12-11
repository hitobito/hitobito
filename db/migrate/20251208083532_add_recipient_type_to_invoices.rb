class AddRecipientTypeToInvoices < ActiveRecord::Migration[8.0]
  def change
    add_column :invoices, :recipient_type, :string
    add_index :invoices, [:recipient_type, :recipient_id]
    remove_index :invoices, [:recipient_id]

    reversible do |dir|
      dir.up do
        execute "UPDATE invoices SET recipient_type = 'Person'"
      end
      dir.down do
        # query if there are any non-Person recipients, then the migration cannot be reverted
        result = execute "SELECT COUNT(*) AS count FROM invoices WHERE recipient_type != 'Person'"
        count = result.first["count"].to_i
        if count > 0
          raise ActiveRecord::IrreversibleMigration,
            "Cannot revert migration because there are #{count} invoices with non-Person recipients"
        end
      end
    end
  end
end
