# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddAddressAdditionToModels < ActiveRecord::Migration[8.0]
  def change
    add_column :people, :address_addition, :string
    add_column :groups, :address_addition, :string
    add_column :additional_addresses, :address_addition, :string
    add_column :event_guests, :address_addition, :string
    add_column :invoices, :recipient_address_addition, :string
  end
end
