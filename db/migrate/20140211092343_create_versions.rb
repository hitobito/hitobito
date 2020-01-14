# encoding: utf-8

#  Copyright (c) 2014, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateVersions < ActiveRecord::Migration[4.2]
  def self.up
    create_table :versions do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.text     :object
      t.text     :object_changes
      t.string   :main_type
      t.integer  :main_id
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]
    add_index :versions, [:main_id, :main_type]
  end

  def self.down
    remove_index :versions, [:item_type, :item_id]
    drop_table :versions
  end
end
