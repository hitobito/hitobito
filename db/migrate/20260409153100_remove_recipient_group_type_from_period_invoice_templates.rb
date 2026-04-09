#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveRecipientGroupTypeFromPeriodInvoiceTemplates < ActiveRecord::Migration[8.0]
  def up
    remove_column :period_invoice_templates, :recipient_group_type
  end

  def down
    add_column :period_invoice_templates, :recipient_group_type, :string
  end
end
