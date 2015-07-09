# encoding: utf-8

#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito_pbs and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_pbs.

require 'csv'

class LocationSeeder

  attr_reader :file

  def initialize
    @file = File.expand_path('../plz_p1_20130121.csv', __FILE__)
  end

  def seed
    Location.delete_all

    bulk_insert
  end

  private

  def bulk_insert
    data.each_slice(500).each_with_index do |values, slice|
      puts "#{self.class.name}: inserting slice #{slice}"
      Location.connection.execute("insert into locations(canton, zip_code, name) values #{values.join(',')}")
    end
  end

  def data
    csv.each_with_object([]) do |row, data|
      data << "('#{row['canton']}', #{row['zip_code']}, \"#{row['name']}\")"
    end.uniq
  end

  def csv
    CSV.read(file, headers: true)
  end
end

