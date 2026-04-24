class ReplaceRecipientNameWithFirstAndLastNameOnInvoices < ActiveRecord::Migration[8.0]
  def up # rubocop:disable Metrics/MethodLength
    change_table :invoices do |t|
      t.string :recipient_first_name
      t.string :recipient_last_name
    end

    # Backfill for Person recipients:
    # If recipient_name matches the concatenated name from people, split it properly
    execute <<~SQL
      UPDATE invoices
      SET recipient_first_name = COALESCE(people.first_name, ''),
          recipient_last_name  = COALESCE(people.last_name, '')
      FROM people
      WHERE invoices.recipient_type = 'Person'
        AND people.id = invoices.recipient_id
        AND invoices.recipient_name = TRIM(CONCAT_WS(' ', people.first_name, people.last_name))
    SQL

    # Backfill for Person recipients where name doesn't match (custom/modified):
    # Store full name in last_name, leave first_name empty
    execute <<~SQL
      UPDATE invoices
      SET recipient_first_name = '',
          recipient_last_name  = invoices.recipient_name
      WHERE invoices.recipient_type = 'Person'
        AND invoices.recipient_first_name IS NULL
    SQL

    # Backfill for non-Person recipients (Groups, etc.):
    # Store full name in last_name, leave first_name empty
    execute <<~SQL
      UPDATE invoices
      SET recipient_first_name = '',
          recipient_last_name  = COALESCE(invoices.recipient_name, '')
      WHERE invoices.recipient_type != 'Person'
        AND invoices.recipient_first_name IS NULL
    SQL

    remove_column :invoices, :recipient_name
  end

  def down
    add_column :invoices, :recipient_name, :string

    execute <<~SQL
      UPDATE invoices
      SET recipient_name = TRIM(CONCAT_WS(' ', recipient_first_name, recipient_last_name))
    SQL

    change_table :invoices do |t|
      t.remove :recipient_first_name
      t.remove :recipient_last_name
    end
  end
end
