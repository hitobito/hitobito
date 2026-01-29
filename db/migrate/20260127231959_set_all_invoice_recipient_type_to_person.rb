#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetAllInvoiceRecipientTypeToPerson < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE invoices
      SET recipient_type = 'Person';
    SQL
  end
end
