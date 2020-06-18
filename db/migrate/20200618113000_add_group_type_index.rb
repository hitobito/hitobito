# encoding: utf-8

#  Copyright (c) 2020, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddGroupTypeIndex < ActiveRecord::Migration[6.0]
  def up
    add_index :groups, :type
  end

  def down
    remove_index :groups, :type
  end
end
