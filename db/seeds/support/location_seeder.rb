# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'csv'

# Imports an ISO-8859-1 CSV with the columns zip_code, town and canton.
#
# To update the locations.csv file:
# * Get the file manually from https://www.post.ch/de/pages/downloadcenter-match
# * Strip all unneeded rows and columns
# * Add a header for zip_code, town and canton
# * Save with separator ; encoded as ISO-8859-1
class LocationSeeder

  FILE = Rails.root.join('db', 'seeds', 'support', 'locations.csv')

  def seed
    Location.delete_all
    bulk_insert
  end

  private

  def bulk_insert
    data.each_slice(500).each_with_index do |values, slice|
      puts " - Location: inserting slice #{slice}"
      Location.connection.execute("insert into locations(canton, zip_code, name) values #{values.join(',')}")
    end
  end

  def data
    csv.each_with_object([]) do |row, data|
      data << "('#{row['canton']}', #{row['zip_code']}, \"#{row['town']}\")"
    end.uniq
  end

  def csv
    CSV.read(FILE, headers: true, col_sep: ';', encoding: 'ISO-8859-1')
  end

end

