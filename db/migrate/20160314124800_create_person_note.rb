# encoding: utf-8

#  Copyright (c) 2012-2016, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito_dsj and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_dsj.

class CreatePersonNote < ActiveRecord::Migration
  def change
    create_table :person_notes do |t|
      t.belongs_to :person, null: false, index: true
      t.belongs_to :author, null: false, class_name: 'Person'
      t.text :text
      t.timestamps
    end
  end
end
