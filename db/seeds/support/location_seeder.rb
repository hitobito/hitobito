# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'csv'

# Imports a CSV with the columns zip_code, town and canton.
#
# To update the locations.csv file:
# * Get the file manually from https://www.post.ch/de/pages/downloadcenter-match
# * Strip all unneeded rows and columns.
#   BEWARE: There are two zip_code columns, only one contains 3006!
# * Add a header for zip_code, town and canton
# * Save with separator ; encoded as UTF-8 (Libre Office: Save as > Edit Filter Settings)
class LocationSeeder

  FILE = Rails.root.join('db', 'seeds', 'support', 'locations.csv')
  SEPARATOR = ';'
  ENCODING = 'UTF-8'

  def seed
    Location.delete_all
    reset_primary_key
    bulk_insert
  end

  private

  def reset_primary_key
    if Location.connection.adapter_name.downcase =~ /mysql/
      Location.connection.execute('ALTER TABLE locations AUTO_INCREMENT = 1')
    end
  end

  def bulk_insert
    data.each_slice(500).each_with_index do |values, slice|
      puts " - Location: inserting slice #{slice}"
      insert = "INSERT INTO locations (canton, zip_code, name) VALUES #{values.join(',')}"
      Location.connection.execute(insert)
    end
  end

  def data
    csv.each_with_object([]) do |row, data|
      data << "(\"#{row['canton'].to_s.downcase}\", \"#{row['zip_code']}\", \"#{row['town']}\")"
    end.uniq
  end

  def csv
    CSV.read(FILE, headers: true, col_sep: SEPARATOR, encoding: ENCODING)
  end

end

