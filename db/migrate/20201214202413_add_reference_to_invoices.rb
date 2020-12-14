# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class AddReferenceToInvoices < ActiveRecord::Migration[6.0]
  def change
    add_column(:invoices, :reference, :string)
    reversible do |dir|
      dir.up do
        execute "UPDATE invoices SET reference = replace(esr_number, ' ', '')"
      end
    end
    change_column_null(:invoices, :reference, false)
  end
end
