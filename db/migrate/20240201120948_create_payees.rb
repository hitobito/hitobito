# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreatePayees < ActiveRecord::Migration[6.1]
  def change
    create_table :payees do |t|
      t.belongs_to :person, null: true
      t.belongs_to :payment, null: false

      t.string :person_name
      t.text :person_address

      t.timestamps
    end
  end
end
