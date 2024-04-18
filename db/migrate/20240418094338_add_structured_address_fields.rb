# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddStructuredAddressFields < ActiveRecord::Migration[6.1]
  def change
    change_table :people do |t|
      t.string :street
      t.string :housenumber
      t.string :address_care_of
      t.string :postbox
    end

    change_table :groups do |t|
      t.string :street
      t.string :housenumber
      t.string :address_care_of
      t.string :postbox
    end
  end
end
