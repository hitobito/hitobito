# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLocations < ActiveRecord::Migration[4.2]
  def change
    create_table(:locations) do |t|
      t.string :name, null: false
      t.string :canton, null: false, limit: 2
      t.integer :zip_code, null: false
    end

    add_index(:locations, [:zip_code, :canton, :name], unique: true)
  end
end
