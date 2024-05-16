# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class RemoveAddressFromPeople < ActiveRecord::Migration[6.1]
  def change
    remove_column :people, :address, :text, limit: 1024
  end
end
