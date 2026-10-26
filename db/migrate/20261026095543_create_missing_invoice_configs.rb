#  Copyright (c) 2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateMissingInvoiceConfigs < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      INSERT INTO invoice_configs (group_id)
      SELECT groups.id FROM groups
      WHERE groups.id = groups.layer_group_id
        AND groups.deleted_at IS NULL
        AND NOT EXISTS (SELECT 1 FROM invoice_configs WHERE invoice_configs.group_id = groups.id)
    SQL
  end

  def down
  end
end
