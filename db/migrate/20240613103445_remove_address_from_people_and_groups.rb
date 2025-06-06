# frozen_string_literal: true

#  Copyright (c) 2024-2024, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
class RemoveAddressFromPeopleAndGroups < ActiveRecord::Migration[6.1]
  def change
    if table_has_data?(:groups) && (table_has_nonempty_address?(:people) || table_has_nonempty_address?(:groups))
      raise "Not all addresses have been migrated into structured form or handled."
    end

    remove_column :people, :search_column, if_exists: true
    remove_column :groups, :search_column, if_exists: true
    remove_column :people, :address, :text, limit: 1024
    remove_column :groups, :address, :text, limit: 1024
  end

  private


  def table_has_data?(table_name)
    count_query = "SELECT COUNT(*) FROM #{quote_table_name(table_name)}"
    ActiveRecord::Base.connection.select_value(count_query).to_i > 0
  end

  def table_has_nonempty_address?(table_name)
    query = <<~SQL
      SELECT COUNT(*)
      FROM #{quote_table_name(table_name)}
      WHERE address IS NOT NULL AND address != ''
    SQL
    ActiveRecord::Base.connection.select_value(query).to_i > 0
  end

  def quote_table_name(name)
    ActiveRecord::Base.connection.quote_table_name(name)
  end
end
