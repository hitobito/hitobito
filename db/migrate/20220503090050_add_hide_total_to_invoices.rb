# frozen_string_literal: true

#  Copyright (c) 2012-2022, Schweizer Wanderwege. This file is part of
#  hitobito_sww and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddHideTotalToInvoices < ActiveRecord::Migration[6.1]
  def change
    add_column :invoices, :hide_total, :boolean, default: false, null: false
  end
end
