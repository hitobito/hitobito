#  Copyright (c) 2026, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class SetBlankShippingMethodsToOwn < ActiveRecord::Migration[8.0]
  TABLES = %i[invoices invoice_runs messages].freeze

  def up
    TABLES.each do |table|
      execute <<~SQL
        UPDATE #{table} SET shipping_method = 'own'
        WHERE shipping_method IS NULL OR shipping_method = ''
      SQL
      change_column_null table, :shipping_method, false
    end
  end

  def down
    TABLES.each { |table| change_column_null table, :shipping_method, true }
  end
end
