# encoding: utf-8

#  Copyright (c) 2020, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddDeviseUnlockTokenToPeople < ActiveRecord::Migration[6.0]
  def self.up
    change_table(:people) do |t|
      t.string   :unlock_token
    end
    add_index :people, :unlock_token,         :unique => true
  end

  def self.down
    remove_index :people, :unlock_token
    remove_column :people, :unlock_token
  end
end
