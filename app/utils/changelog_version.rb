# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogVersion
  attr_accessor :major_version, :minor_version, :log_entries, :version

  def initialize(header_line)
    values         = header_line.split('.')
    @version       = header_line
    @major_version = values.first.to_i
    @minor_version = values.second.downcase == 'x' ? Float::INFINITY : values.second.to_i
    @log_entries   = []
  end

  def <=>(other)
    [major_version, minor_version] <=> [other.major_version, other.minor_version]
  end

  def to_markdown
    [label_markdown, log_entries.map(&:to_markdown)].flatten.join("\n")
  end

  private

  def label_markdown
    "## Version #{version}"
  end
end
