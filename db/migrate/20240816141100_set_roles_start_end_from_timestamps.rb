# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetRolesStartEndFromTimestamps < ActiveRecord::Migration[6.1]
  def change
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE roles
          SET
            start_on = created_at,
            end_on = COALESCE(deleted_at, delete_on)
        SQL
      end
    end
  end
end
