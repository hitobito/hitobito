# encoding: utf-8

#  Copyright (c) 2012-2019, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadFile

  DIRECTORY = Pathname.new(Settings.downloads.folder)

  attr_accessor :filename, :filetype

  def initialize(filename, filetype = :txt)
    @filename = filename
    @filetype = filetype
  end

  class << self
    def create_name(filename, person_id)
      "#{filename}_#{Time.now.to_i}-#{person_id}"
    end
  end

  def write(data)
    FileUtils.mkdir_p(DIRECTORY) unless File.directory?(DIRECTORY)
    filetype.to_sym == :csv ? write_csv(data) : File.write(full_path, data)
  end

  def downloadable?(person)
    return false unless full_path.to_s =~ /-(\w+?)\./
    File.exist?(full_path) &&
      full_path.to_s.match(/-(\w+?)\./)[1] == person.id.to_s
  end

  def full_path
    DIRECTORY.join("#{filename}.#{filetype}")
  end

  private

  def write_csv(data)
    File.open(full_path, "w:#{Settings.csv.encoding}") do |f|
      f.write(data)
    end
  end

end
