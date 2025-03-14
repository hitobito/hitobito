# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

class AddPersonIdToSessions < ActiveRecord::Migration[7.1]
  def change
    change_table(:sessions) do |t|
      t.belongs_to :person, index: true
    end
  end
end
