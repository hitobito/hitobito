#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class CreateEventGuests < ActiveRecord::Migration[7.1]
  def change
    create_table :event_guests do |t|
      t.belongs_to :main_applicant, null: false

      t.string :first_name
      t.string :last_name
      t.string :nickname
      t.string :company_name
      t.boolean :company
      t.string :email
      t.string :address_care_of
      t.string :street
      t.string :housenumber
      t.string :postbox
      t.string :zip_code
      t.string :town
      t.string :country
      t.string :gender
      t.date :birthday
      t.string :phone_number
      t.string :language

      t.timestamps
    end
  end
end
