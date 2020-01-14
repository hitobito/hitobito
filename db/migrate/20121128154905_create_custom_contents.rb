# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateCustomContents < ActiveRecord::Migration[4.2]
  def change
    create_table :custom_contents do |t|
      t.string :key, null: false, unique: true
      t.string :label, null: false, unique: true
      t.string :subject
      t.text :body
      t.string :placeholders_required
      t.string :placeholders_optional
    end
  end
end
