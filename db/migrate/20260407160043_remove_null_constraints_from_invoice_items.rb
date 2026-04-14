# frozen_string_literal: true

#  Copyright (c) 2026-2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveNullConstraintsFromInvoiceItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :invoice_items, :unit_cost, true
    change_column_null :invoice_items, :count, true
  end
end
