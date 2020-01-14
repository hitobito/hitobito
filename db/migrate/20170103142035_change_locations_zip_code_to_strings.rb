# encoding: utf-8

#  Copyright (c) 2017, hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangeLocationsZipCodeToStrings < ActiveRecord::Migration[4.2]
  def change
    change_column :locations, :zip_code, :string, null: false
  end
end
