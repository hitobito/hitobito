#  Copyright (c) 2026, BdP and DPSG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ValidateGroupsFilters < ActiveRecord::Migration[8.0]
  def up
    change_column_default :groups_filters, :active_at, -> { "NOW()" }
    change_column_null :groups_filters, :group_type, false
    change_column_null :groups_filters, :active_at, false
    change_column_null :groups_filters, :parent_id, false
  end

  def down
    change_column_null :groups_filters, :parent_id, true
    change_column_null :groups_filters, :active_at, true
    change_column_null :groups_filters, :group_type, true
    change_column_default :groups_filters, :active_at, nil
  end
end
