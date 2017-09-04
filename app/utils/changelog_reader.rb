# encoding: utf-8

#  Copyright (c) 2012-2016, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogReader
  class << self
    def changelog
      ChangelogReader.new.changelogs
    end
  end

  def initialize
    @changelogs = []
    collect_changelog_data
  end

  def changelogs
    @changelogs.sort.reverse
  end

  private

  def collect_changelog_data
    changelog_files_content = read_changelog_files(changelog_file_paths)
    parse_changelog_lines(changelog_files_content)
  end

  def parse_changelog_lines(changelog_files_content)
    version = ''
    changelog_files_content.each_line do |l|
      if h = changelog_header_line(l)
        version = find_or_create_version(h)
      elsif e = changelog_entry_line(l)
        add_changelog_entry(version, e)
      end
    end
  end

  def read_changelog_files(files_path)
    data = ''
    files_path.each do |p|
      if File.exist?(p)
        data += File.read(p)
      end
    end
    data
  end

  def changelog_file_paths
    file_paths = ['CHANGELOG.md']
    Wagons.all.each do |w|
      file_paths << "#{w.root}/CHANGELOG.md"
    end
    file_paths
  end

  def changelog_header_line(h)
    h.strip!
    h[/^## [^\s]+ ((\d+\.)?(\*|x|\d+))$/i, 1]
  end

  def changelog_entry_line(e)
    e.strip!
    e[/^\*\s*(.*)/, 1]
  end

  def find_or_create_version(header_line)
    version = find_version(header_line)
    unless version
      version = ChangelogVersion.new(header_line)
      @changelogs << version
    end
    version
  end

  def find_version(header_line)
    @changelogs.find do |v|
      v.version == header_line
    end
  end

  def add_changelog_entry(version, entry)
    version.log_entries << entry
  end
end
