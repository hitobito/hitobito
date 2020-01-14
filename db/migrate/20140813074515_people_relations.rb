# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class PeopleRelations < ActiveRecord::Migration[4.2]
  def change
    create_table :people_relations do |t|
      t.integer :head_id, null: false
      t.integer :tail_id, null: false
      t.string :kind, null: false
    end

    add_index :people_relations, :head_id
    add_index :people_relations, :tail_id
  end
end
