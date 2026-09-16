# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddCancelledAtToInvoices < ActiveRecord::Migration[7.1]
  def change
    add_column :invoices, :cancelled_at, :date
  end
end
