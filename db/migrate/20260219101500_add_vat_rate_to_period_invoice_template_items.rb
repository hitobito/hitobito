#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddVatRateToPeriodInvoiceTemplateItems < ActiveRecord::Migration[8.0]
  def change
    add_column :period_invoice_template_items, :vat_rate, :decimal, precision: 5, scale: 2, if_not_exists: true
  end
end
