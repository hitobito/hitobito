#  Copyright (c) 2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddTranslationTableForPaymentReminderConfig < ActiveRecord::Migration[7.1]
  def up
    PaymentReminderConfig.create_translation_table!(
      { title: :string,
        text: :string },
      { migrate_data: true }
    )
    remove_column :payment_reminder_configs, :title
    remove_column :payment_reminder_configs, :text
  end

  def down
    PaymentReminderConfig.drop_translation_table! migrate_data: true
    add_column :payment_reminder_configs, :title, :string
    add_column :payment_reminder_configs, :text, :string
  end
end
