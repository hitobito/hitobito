class AddUniqueIndexOnGroupIdToInvoiceConfigs < ActiveRecord::Migration[8.0]
  def up
    # Before we can add a unique index on group_id, we need to make sure there are no duplicate conflicting
    # records. We keep the one with the lowest id for each group_id and delete the others.
    execute <<~SQL
      DELETE FROM invoice_configs
      WHERE id NOT IN (
        SELECT MIN(id)
        FROM invoice_configs
        GROUP BY group_id
      )
    SQL

    remove_index :invoice_configs, :group_id
    add_index :invoice_configs, :group_id, unique: true
  end

  def down
    remove_index :invoice_configs, :group_id
    add_index :invoice_configs, :group_id
  end
end
