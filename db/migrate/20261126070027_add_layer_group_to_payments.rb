#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLayerGroupToPayments < ActiveRecord::Migration[8.1]
  def up
    add_reference :payments, :layer_group, type: :integer, index: true, foreign_key: false

    execute <<~SQL
      UPDATE payments SET layer_group_id = groups.layer_group_id
      FROM invoices JOIN groups ON groups.id = invoices.group_id
      WHERE invoices.id = payments.invoice_id
    SQL
  end

  def down
    remove_reference :payments, :layer_group
  end
end
