# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
#
class AddDeleteAtToRoles < ActiveRecord::Migration[6.1]
  def change
    change_table(:roles) do |t|
      t.date :delete_on
    end
    reversible do |dir|
      dir.up do
        # required to make this work on github actions deployment build
        return true if Role.none?

        execute "UPDATE roles SET delete_on = DATE(deleted_at), deleted_at = NULL WHERE deleted_at >= NOW()"
      end
    end
  end
end
