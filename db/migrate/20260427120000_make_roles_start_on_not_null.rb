#  Copyright (c) 2026, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MakeRolesStartOnNotNull < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up { execute "UPDATE roles SET start_on = created_at::date WHERE start_on IS NULL" }
    end

    change_column_default :roles, :start_on, -> { 'CURRENT_TIMESTAMP::date' }
    change_column_null :roles, :start_on, false
  end
end
