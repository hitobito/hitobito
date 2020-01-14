# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePeopleFilters < ActiveRecord::Migration[4.2]
  def change
    create_table :people_filters do |t|
      t.string :name, null: false
      t.belongs_to :group
      t.string :group_type
      t.string :kind, null: false
    end

    create_table :people_filter_role_types do |t|
      t.belongs_to :people_filter
      t.string :role_type, null: false
    end
  end
end
