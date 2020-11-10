# encoding: utf-8

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class AddInvoiceLists < ActiveRecord::Migration[6.0]
  def change
    create_table :invoice_lists do |t|
      t.belongs_to :receiver, polymorphic: true
      t.belongs_to :group
      t.belongs_to :creator
      t.string :title, null: false
      t.decimal :amount_total, precision: 15, scale: 2, default: 0, null: false
      t.decimal :amount_paid, precision: 15, scale: 2, default: 0, null: false
      t.integer :recipients_total, default: 0, null: false
      t.integer :recipients_paid, default: 0, null: false
      t.integer :recipients_processed, default: 0, null: false
      t.timestamps
    end

    change_table :invoices do |t|
      t.belongs_to :invoice_list, null: true
    end
  end
end
