# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddLayerIdToGroup < ActiveRecord::Migration[4.2]
  def up
    add_column :groups, :layer_group_id, :integer
    Group.find_each do |g|
      g.update_column(:layer_group_id, self.class.layer ? g.id : g.layer_hierarchy.last.id)
    end
    add_index :groups, :layer_group_id
  end

  def down
    remove_column :groups, :layer_group_id
  end
end
