#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigratePaperTrailVersionsToNewRoleDates < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE versions
      SET object_changes = REPLACE(
        REPLACE(object_changes,
        'created_at:', 'start_on:'),
        'deleted_at:', 'end_on:'
      )
      WHERE item_type = 'Role';
    SQL
  end

  def down
    execute <<-SQL
      UPDATE versions
      SET object_changes = REPLACE(
        REPLACE(object_changes,
        'start_on:', 'created_at:'),
        'end_on:', 'deleted_at:'
      )
      WHERE item_type = 'Role';
    SQL
  end
end
