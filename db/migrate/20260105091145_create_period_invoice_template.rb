#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePeriodInvoiceTemplate < ActiveRecord::Migration[8.0]
  def change
    create_table :period_invoice_templates do |t|
      t.string :name, null: false
      t.date :start_on, null: false
      t.date :end_on
      t.string :recipient_group_type
      t.belongs_to :group, null: false
      t.timestamps
    end

    add_reference :invoice_runs, :period_invoice_template, null: true, type: :integer
    InvoiceRun.reset_column_information
  end
end
