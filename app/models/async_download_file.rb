# frozen_string_literal: true

#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadFile < ApplicationRecord
  DIRECTORY = Pathname.new(Settings.downloads.folder)

  class << self
    def create_name(filename, person_id)
      "#{filename.to_s.parameterize}_#{Time.now.to_i}-#{person_id}"
    end

    def parse_filename(filename)
      filename.match(/\A(.*)_(\d+)-(\d+)\z/)[1..-1]
    end

    def from_filename(filename, filetype = :txt)
      name, timestamp, person_id = parse_filename(filename)

      file = find_or_create_by(
        name: name, timestamp: timestamp, person_id: person_id
      )
      file.update!(filetype: filetype)
      file
    end
  end

  def filename
    Pathname.new("#{name}_#{timestamp}-#{person_id}.#{filetype}")
  end

  def full_path
    DIRECTORY.join(filename)
  end

  def write(data)
    DIRECTORY.mkpath unless File.directory?(DIRECTORY)

    case filetype.to_sym
    when :csv
      File.open(full_path, "w:#{Settings.csv.encoding}") do |f|
        f.write(data)
      end
    when :pdf
      File.binwrite(full_path, data)
    else
      File.write(full_path, data)
    end
  end

  def downloadable?(person)
    (person_id == person.id) && File.exist?(full_path)
  end

  def read
    data = File.read(full_path)

    if filetype == 'csv'
      data = data.force_encoding(Settings.csv.encoding)
    end

    data
  end
end
