# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddPrimaryGroupId < ActiveRecord::Migration[4.2]
  def up
    add_column :people, :primary_group_id, :integer
    remove_column :people_filters, :kind
  end

  def down
    remove_column :people, :primary_group_id
    add_column :people_filters, :kind, :string
  end
end
