# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddCarddavTokenToPeople < ActiveRecord::Migration[8.0]
  def change
    add_column(:people, :carddav_token, :string, null: true)
    add_index(:people, :carddav_token, unique: true)
  end
end
