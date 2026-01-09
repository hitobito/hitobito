#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePeriodInvoiceTemplateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :period_invoice_template_items do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.string :cost_center
      t.string :account
      t.text :dynamic_cost_parameters
      t.belongs_to :period_invoice_template, null: false
      t.timestamps
    end

    # TODO:
    #  migrate invoice_items#type values from InvoiceItem::FixedFee to the correct class
    #  migrate invoice_items#unit_cost
  end
end
