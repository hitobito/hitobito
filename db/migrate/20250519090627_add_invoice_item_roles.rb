# frozen_string_literal: true

#  Copyright (c) 2012-2025, Swiss Badminton. This file is part of
#  hitobito_swb and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AddInvoiceItemRoles < ActiveRecord::Migration[7.1]
  def change
    create_table(:invoice_item_roles) do |t|
      t.belongs_to :invoice_item
      t.belongs_to :role
      t.integer :year, null: false
      t.integer :layer_group_id, null: false
      t.timestamps

      t.index [:role_id, :year], unique: true
    end
  end
end
