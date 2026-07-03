# frozen_string_literal: true

#  Copyright (c) 2026, Puzzle ITC. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito

class ConvertZipColumnsToString < ActiveRecord::Migration[8.0]
  # Remove generated search_column if it exists to allow zip_code type change.
  # This is necessary because the search index includes the zip_code column
  # and Postgres does not allow to change the type of a column that is part
  # of the index.
  # It will be recreated automatically.
  def remove_search_column(table)
    remove_column table, :search_column, if_exists: true
  end

  def convert_zip_column_to_int(table)
    change_column table, :zip_code, :integer, using: 'zip_code::integer'
  end

  def up
    %i[groups addresses].each do |table|
      remove_search_column(table)
      change_column table, :zip_code, :string
    end
  end

  def down
    remove_search_column(:groups)
    # Clear zip_code values that are incompatible with rolling back to int
    execute "UPDATE groups SET zip_code = NULL WHERE zip_code !~ '^[1-9][0-9]*$'"
    convert_zip_column_to_int(:groups)

    remove_search_column(:addresses)
    # addresses.zip_code has a NOT NULL constraint so we can not NULLify values
    # that are incompatible with rolling back to int. So we delete those rows.
    execute "DELETE FROM addresses WHERE zip_code !~ '^[1-9][0-9]*$'"
    convert_zip_column_to_int(:addresses)
  end
end
