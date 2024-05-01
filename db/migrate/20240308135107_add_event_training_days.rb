# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class AddEventTrainingDays < ActiveRecord::Migration[6.1]

  def up
    if column_exists?(:events, :training_days)
      change_column :events, :training_days, :decimal, precision: 5, scale: 2
    else
      add_column :events, :training_days, :decimal, precision: 5, scale: 2
    end

    add_column :qualification_kinds, :required_training_days, :decimal, precision: 5, scale: 2
  end

  def down
    remove_column :qualification_kinds, :required_training_days
    remove_column :events, :training_days
  end

end
