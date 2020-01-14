# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddUserstampColumnsToPeopleAndGroups < ActiveRecord::Migration[4.2]
  def change

    change_table :groups do |t|
      t.integer :creator_id
      t.integer :updater_id
      t.integer :deleter_id
    end

    change_table :people do |t|
      t.integer :creator_id
      t.integer :updater_id
    end

  end
end
