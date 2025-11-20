class ChangePaymentReminderConfigsTextTypeToText < ActiveRecord::Migration[8.0]
  def up
    change_column :payment_reminder_config_translations, :text, :text
  end

  def down
    change_column :payment_reminder_config_translations, :text, :string
  end
end
