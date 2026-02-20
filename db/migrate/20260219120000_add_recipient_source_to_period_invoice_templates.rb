#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddRecipientSourceToPeriodInvoiceTemplates < ActiveRecord::Migration[8.0]
  def change
    add_reference :period_invoice_templates, :recipient_source, polymorphic: true, foreign_key: false, type: :integer
  end
end
