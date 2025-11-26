#  Copyright (c) 2012-2025, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangePaymentReminderConfigsTextTypeToText < ActiveRecord::Migration[8.0]
  def up
    change_column :payment_reminder_config_translations, :text, :text
  end

  def down
    change_column :payment_reminder_config_translations, :text, :string
  end
end
