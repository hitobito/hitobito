# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MigrateRoleTimestampsAndFutureRoles < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        say "Migrate timestamps for all roles except FutureRoles", true
        execute <<~SQL
          UPDATE roles
          SET
            start_on = created_at,
            end_on = COALESCE(deleted_at, delete_on)
          WHERE type != 'FutureRole'
        SQL

        say "Migrate timestamps and type for FutureRoles except deleted ones", true
        execute <<~SQL
          UPDATE roles
          SET
            type = convert_to,
            start_on = convert_on,
            end_on = delete_on
          WHERE type = 'FutureRole'
          AND deleted_at IS NULL
        SQL

        say "Remove remaining FutureRoles (the ones marked as deleted)", true
        execute <<~SQL
          DELETE FROM roles
          WHERE type = 'FutureRole'
        SQL
      end
    end
  end
end
