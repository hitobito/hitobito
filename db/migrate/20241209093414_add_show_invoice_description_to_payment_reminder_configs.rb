class AddShowInvoiceDescriptionToPaymentReminderConfigs < ActiveRecord::Migration[7.0]
  def change
    add_column :payment_reminder_configs, :show_invoice_description, :boolean, null: false, default: true
    add_column :payment_reminders, :show_invoice_description, :boolean, null: false, default: true
  end
end
