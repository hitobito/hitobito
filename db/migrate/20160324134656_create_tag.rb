# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateTag < ActiveRecord::Migration[4.2]
  def change
    create_table :tags do |t|
      t.string :name, null: false, index: true
      t.references :taggable, polymorphic: true, index: true
      t.timestamps null: false
    end
  end
end
