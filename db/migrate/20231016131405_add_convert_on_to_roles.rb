# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddConvertOnToRoles < ActiveRecord::Migration[6.1]
  def change
    change_table(:roles) do |t|
      t.date :convert_on
      t.string :convert_to
    end
  end
end
