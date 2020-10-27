# frozen_string_literal: true

#  Copyright (c) 2012-2020, CVP Schweiz. This file is part of
#  hitobito_cvp and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cvp.

class AddPersonDuplicates < ActiveRecord::Migration[6.0]
  def change
    create_table(:person_duplicates) do |t|
      t.integer :person_1_id, null: false
      t.integer :person_2_id, null: false
      t.boolean :acknowledged, null: false, default: false

      t.timestamps
    end

    add_foreign_key(:person_duplicates, :people, column: :person_1_id)
    add_foreign_key(:person_duplicates, :people, column: :person_2_id)

    add_index(:person_duplicates, [:person_1_id, :person_2_id], unique: true)
  end
end
