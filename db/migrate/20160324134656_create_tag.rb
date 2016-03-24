# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class CreateTag < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name, null: false, index: true
      t.references :taggable, polymorphic: true, index: true
      t.timestamps null: false
    end
  end
end
