# frozen_string_literal: true

#  Copyright (c) 2012-2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadFile < ApplicationRecord
  class << self
    FILENAME_REGEX = /\A(.*)_(\d+)-(\d+)\z/.freeze

    def create_name(filename, person_id)
      "#{filename.to_s.parameterize}_#{Time.now.to_i}-#{person_id}"
    end

    def parse_filename(filename)
      filename.match(FILENAME_REGEX)[1..-1]
    end

    def from_filename(filename, filetype = :txt)
      return unless parseable?(filename)

      name, timestamp, person_id = parse_filename(filename)

      file = find_or_create_by(
        name: name, timestamp: timestamp, person_id: person_id
      )
      file.update!(filetype: filetype)
      file
    end

    def maybe_from_filename(filename, person_id, filetype)
      if parseable?(filename)
        from_filename(filename, filetype)
      else
        from_filename(create_name(filename, person_id), filetype)
      end
    end

    def parseable?(filename)
      filename =~ FILENAME_REGEX
    end
  end

  has_one_attached :generated_file

  before_destroy do
    generated_file.purge if generated_file.attached?
  end

  def filename
    "#{name}.#{filetype}"
  end

  def to_s
    partial = " (#{progress}%)" if progress.present?

    "<AsyncDownloadFile##{id}: #{filename}#{partial}>"
  end

  def downloadable?(person)
    (person_id == person.id) && generated_file.attached?
  end

  def write(data)
    io = StringIO.new

    case filetype.to_sym
    when :csv then io.set_encoding(Settings.csv.encoding)
    when :pdf then io.binmode
    end

    io.write(data)
    io.rewind # make ActiveStorage's checksum-calculation deterministic

    generated_file.attach(io: io, filename: filename.to_s)
  end
end
