# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangePaymentRemindersTextToText < ActiveRecord::Migration[8.0]
  def up
    change_column :payment_reminders, :text, :text
  end

  def down
    change_column :payment_reminders, :text, :string
  end
end
