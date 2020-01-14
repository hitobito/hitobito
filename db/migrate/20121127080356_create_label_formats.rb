# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateLabelFormats < ActiveRecord::Migration[4.2]
  def change
    create_table :label_formats do |t|
      t.string :name, null: false, unique: true
      t.string :page_size, null: false, default: 'A4'
      t.boolean :landscape, null: false, default: false
      t.float :font_size, null: false, default: 11
      t.float :width, null: false
      t.float :height, null: false
      t.integer :count_horizontal, null: false
      t.integer :count_vertical, null: false
      t.float :padding_top, null: false
      t.float :padding_left, null: false
    end

    add_column :people, :last_label_format_id, :integer

    add_index :roles, :type
  end
end
