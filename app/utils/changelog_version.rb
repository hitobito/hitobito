# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class ChangelogVersion
  attr_accessor :major_version, :minor_version, :log_entries, :version

  UNRELEASED_VERSION_STRING = "unreleased"
  WILDCARD_VERSION_STRINGS = ["*", "x"].freeze

  def initialize(version_string)
    @version = version_string.to_s
    @major_version, @minor_version = parse_version
    @log_entries = []
  end

  def <=>(other)
    [major_version, minor_version] <=> [other.major_version, other.minor_version]
  end

  def to_markdown
    [label_markdown, log_entries.map(&:to_markdown)].flatten.join("\n")
  end

  def to_s = version

  private

  def parse_version
    return [Float::INFINITY, Float::INFINITY] if version.downcase == UNRELEASED_VERSION_STRING

    segments = version.split(".")
    major = segments.first.to_i
    minor = WILDCARD_VERSION_STRINGS.include?(segments.second.downcase) ? Float::INFINITY : segments.second.to_i

    [major, minor]
  end

  def label_markdown
    "## Version #{version}"
  end
end
