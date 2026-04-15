#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddShippingAttrsToInvoiceRunsAndInvoices < ActiveRecord::Migration[8.0]
  def change
    change_table(:invoices) do |t|
      t.column :shipping_method, :string, default: :own
      t.column :pp_post, :string
    end

    change_table(:invoice_runs) do |t|
      t.column :shipping_method, :string, default: :own
      t.column :pp_post, :string
    end
  end
end
