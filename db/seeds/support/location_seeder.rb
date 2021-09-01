# frozen_string_literal: true

#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

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

  SEED_MARKER = 'locations seeded'

  def seed
    return true if marked_as_seeded?
    raise 'Currently, this only works with MySQL' unless mysql?

    truncate_locations
    bulk_insert

    mark_as_seeded! if seeded?
  end

  private

  def marked_as_seeded?
    ActiveRecord::InternalMetadata[SEED_MARKER].present?
  end

  def mark_as_seeded!
    ActiveRecord::InternalMetadata[SEED_MARKER] = Location.count
  end

  def seeded?
    Location.count == csv.count
  end

  def mysql?
    Location.connection.adapter_name.downcase =~ /mysql/
  end

  def truncate_locations
    Location.connection.truncate(Location.table_name, 'Truncate Location')
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
