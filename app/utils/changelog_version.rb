# encoding: utf-8
class ChangelogVersion
  attr_accessor :major_version, :minor_version, :log_entries

  def initialize(header_line)
    values = header_line.split(".")
    @major_version = values.first.to_i
    @minor_version = values.second.to_i
    @log_entries = []
  end

  def <=>(other)
    [self.major_version, self.minor_version] <=> [other.major_version, other.minor_version]
  end

  def label
    "Version #{version}"
  end

  def version
  "#{major_version}.#{minor_version}"
  end
end