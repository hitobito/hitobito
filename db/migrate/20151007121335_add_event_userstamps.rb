# encoding: utf-8

#  Copyright (c) 2015, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddEventUserstamps < ActiveRecord::Migration[4.2]
  def change
    change_table :events do |t|
      t.integer :creator_id
      t.integer :updater_id
    end
  end
end
