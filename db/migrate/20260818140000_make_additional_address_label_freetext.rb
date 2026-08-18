# frozen_string_literal: true

#  Copyright (c) 2012-2026, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# label is no longer a predefined, per-contactable-unique value (that's now
# ContactAccountCategory#key, enforced by ContactAccount#assert_category_unique_per_contactable);
# it becomes a plain optional free-text addition, like the other three
# ContactAccount models already allow.
class MakeAdditionalAddressLabelFreetext < ActiveRecord::Migration[8.0]
  def up
    remove_index :additional_addresses, column: [:contactable_id, :contactable_type, :label]
    change_column_null :additional_addresses, :label, true
  end

  def down
    change_column_null :additional_addresses, :label, false
    add_index :additional_addresses, [:contactable_id, :contactable_type, :label], unique: true
  end
end
