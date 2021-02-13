# encoding: utf-8

#  Copyright (c) 2012-2016, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe ChangelogReader do

  subject { ChangelogReader.new }

  context "parsing changelog lines" do
    let(:changelog_lines) do
      [
        "foo", # invalid line
        "## Version 1.1",
        "foo", # invalid line
        "* change",
        "* change two",
        "", # invalid line
        "## Version 1.X",
        "* far future change",
        "## Version 2.3",
        "* change",
        "## Version 1.1",
        "* another change",
      ].join("\n")
    end
    before do
      ChangelogReader.instance_variable_set(:@changelogs, [])
    end

    it "creates hash with changelog entries" do
      allow_any_instance_of(ChangelogReader).to receive(:collect_changelog_data).and_return(nil)

      subject.send(:parse_changelog_lines, changelog_lines)

      changelogs = subject.instance_variable_get(:@changelogs)
      expect(changelogs.count).to eq(3)

      version11 = changelogs[0]
      expect(version11.log_entries.count).to eq(3)
      expect(version11.version).to eq("1.1")
      expect(version11.log_entries[0]).to eq("change")
      expect(version11.log_entries[1]).to eq("change two")
      expect(version11.log_entries[2]).to eq("another change")

      version1x = changelogs[1]
      expect(version1x.log_entries.count).to eq(1)
      expect(version1x.version).to eq("1.X")
      expect(version1x.log_entries[0]).to eq("far future change")

      version23 = changelogs[2]
      expect(version23.log_entries.count).to eq(1)
      expect(version23.version).to eq("2.3")
      expect(version23.log_entries[0]).to eq("change")
    end
  end

  it "parses header line" do
    line = subject.send(:changelog_header_line, "## Version 1.0")
    expect("1.0").to eq(line)
  end

  it "parses entry line" do
    line = subject.send(:changelog_entry_line, "* change")
    expect(line).to eq("change")
  end

  it "doesnt parse if invalide line" do
    line = subject.send(:changelog_entry_line, "invalid")
    expect(line).to be_falsey

    line = subject.send(:changelog_header_line, "invalid")
    expect(line).to be_falsey
  end

  it "sorts changelogs by version" do
    v1 = ChangelogVersion.new("1.1")
    v2 = ChangelogVersion.new("2.3")
    v3 = ChangelogVersion.new("1.11")
    v4 = ChangelogVersion.new("2.15")
    v5 = ChangelogVersion.new("1.X")
    unsorted = [v1, v2, v3, v4, v5]

    sorted = unsorted.sort.reverse

    expect(sorted[0]).to eq(v4)
    expect(sorted[1]).to eq(v2)
    expect(sorted[2]).to eq(v5)
    expect(sorted[3]).to eq(v3)
    expect(sorted[4]).to eq(v1)

    expect(sorted.map(&:version)).to eq(%w( 2.15 2.3 1.X 1.11 1.1 ))
  end

  it "reads existing changelog file" do
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return("example text")

    files_path = ["test"]

    data = subject.send(:read_changelog_files, files_path)

    expect(data).to eq("example text")
  end

  it "does not read unexisting changelog file" do
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:read).and_return("test")

    files_path = ["test"]

    data = subject.send(:read_changelog_files, files_path)

    expect(data).to be_blank
  end

  it "sets changelog files path" do
    wagon = instance_double("Wagon", root: "files")
    wagons = [wagon]
    allow(Wagons).to receive(:all).and_return(wagons)

    files_path = subject.send(:changelog_file_paths)

    expect(files_path[0]).to eq("CHANGELOG.md")
    expect(files_path[1]).to eq("files/CHANGELOG.md")
  end
end
