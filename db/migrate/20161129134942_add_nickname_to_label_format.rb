# encoding: utf-8

#  Copyright (c) 2016, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddNicknameToLabelFormat < ActiveRecord::Migration[4.2]
  def change
    add_column :label_formats, :nickname, :boolean, null: false, default: false
    add_column :label_formats, :pp_post, :string, limit: 23  # PLZ + {18}
  end
end
