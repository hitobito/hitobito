# encoding: utf-8

#  Copyright (c) 2016, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddUserIdToLabelFormat < ActiveRecord::Migration[4.2]
  def change
    add_column :label_formats, :person_id, :integer
    add_column :people, :show_global_label_formats, :boolean, default: true, null: false
  end
end
