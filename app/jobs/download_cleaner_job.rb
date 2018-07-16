# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DownloadCleanerJob < RecurringJob

  run_every 1.day

  def perform_internal
    remove_old_downloads
  end

  private

  def remove_old_downloads
    removable_files.each do |file|
      File.delete(file)
    end
  end

  def removable_files
    Dir[AsyncDownloadFile::DIRECTORY.join('*')].collect do |fullpath|
      timestamp = calculate_timestamp(fullpath)
      next unless timestamp
      next unless older_than_a_day?(timestamp)
      fullpath
    end.compact
  end

  def calculate_timestamp(fullpath)
    filename = fullpath.match(/\d*-(\w+?)\.\w*$/)
    return unless filename
    filename[0].match(/(\d*)-/)[1]
  end

  def older_than_a_day?(timestamp)
    1.day.ago.to_i >= timestamp.to_i
  end
end
