# frozen_string_literal: true

#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RefactorTableDisplays < ActiveRecord::Migration[6.1]
  def change
    TableDisplay.truncate

    add_column :table_displays, :table_model_class, :string, null: false
    add_index :table_displays, [:person_id, :table_model_class], unique: true

    remove_index :table_displays, [:person_id, :type], unique: true
    remove_column :table_displays, :type

    TableDisplay.reset_column_information
  end
end
