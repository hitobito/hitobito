#  Copyright (c) 2026, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddGroupFilter < ActiveRecord::Migration[8.0]
  def change
    create_table :groups_filters do |t|
      t.string :group_type
      t.date :active_at
      t.belongs_to :parent
    end
  end
end
