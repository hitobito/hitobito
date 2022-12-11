# frozen_string_literal: true

#  Copyright (c) 2022, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddWhodunnitTypeToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :whodunnit_type, :string, null: false, default: Person.sti_name
  end
end
