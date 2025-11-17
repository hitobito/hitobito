# frozen_string_literal: true

#  Copyright (c) 2023, CEVI Schweiz, Pfadibewegung Schweiz,
#  Jungwacht Blauring Schweiz, Pro Natura, Stiftung für junge Auslandschweizer.
#  This file is part of hitobito_youth and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_youth.

class CreatePeopleManagers < ActiveRecord::Migration[6.1]
  def change
    create_table(:people_managers, if_not_exists: true) do |t|
      t.integer :manager_id, null: false
      t.integer :managed_id, null: false

      t.timestamps

      t.index [:manager_id, :managed_id], unique: true
    end
  end
end
