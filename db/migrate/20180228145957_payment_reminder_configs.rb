class PaymentReminderConfigs < ActiveRecord::Migration[4.2]

  def change
    create_table(:payment_reminder_configs) do |t|
      t.belongs_to :invoice_config, index: true, null: false
      t.string :title, null: false
      t.string :text, null: false
      t.integer :due_days, null: false
      t.integer :level, null: false
    end

    reversible do |dir|
      dir.up do
        execute("UPDATE invoices SET state='cancelled' WHERE state IN ('reminded', 'overdue')")
        execute("DELETE FROM payment_reminders")
      end
    end

    change_table(:payment_reminders) do |t|
      t.string :title
      t.string :text
      t.integer :level
    end

    remove_column(:payment_reminders, :message, :text)
  end

end
