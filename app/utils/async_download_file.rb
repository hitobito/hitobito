#  Copyright (c) 2012-2021, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class AsyncDownloadFile

  DIRECTORY = Pathname.new(Settings.downloads.folder)
  PERSON_ID = /-(\w+?)\./

  attr_accessor :filename, :filetype

  def initialize(filename, filetype = :txt)
    @filename = filename
    @filetype = filetype
  end

  class << self
    def create_name(filename, person_id)
      "#{filename.to_s.parameterize}_#{Time.now.to_i}-#{person_id}"
    end
  end

  def write(data)
    FileUtils.mkdir_p(DIRECTORY) unless File.directory?(DIRECTORY)
    case filetype.to_sym
    when :csv
      write_csv(data)
    when :pdf
      File.binwrite(full_path, data)
    else
      File.write(full_path, data)
    end
  end

  def downloadable?(person)
    return false unless full_path.to_s =~ PERSON_ID
    File.exist?(full_path) &&
      full_path.to_s.match(PERSON_ID)[1] == person.id.to_s
  end

  def full_path
    DIRECTORY.join("#{filename}.#{filetype}")
  end

  def progress
    progress_file.exist? ? progress_file.read : nil
  end

  private

  def write_csv(data)
    File.open(full_path, "w:#{Settings.csv.encoding}") do |f|
      f.write(data)
    end
  end

  def progress_file
    @progress_file ||= DIRECTORY.join("#{filename}.progress")
  end

end
