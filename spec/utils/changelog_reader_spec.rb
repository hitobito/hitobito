# encoding: utf-8

require 'spec_helper'

describe ChangelogReader do
  context 'adds new line to changelogs' do
    version = "version 1.0"
    before {
      changelogs = {}
      changelogs[version] = []
      ChangelogReader.instance_variable_set(:@version, version)
      ChangelogReader.instance_variable_set(:@changelogs, changelogs)
    }
    it{
      line = "* test"
      ChangelogReader.send(:add_line, line)

      changelogs = ChangelogReader.instance_variable_get(:@changelogs)
      expect(" test").to eq(changelogs[version].first)
    }
  end

  it 'sets new version' do
      line = "## version 1.0"
      ChangelogReader.send(:add_line, line)

      version = ChangelogReader.instance_variable_get(:@version)
      expect(" version 1.0").to eq(version)
  end

  it 'does nothing' do
    line = "test"
    ChangelogReader.send(:add_line, line)

    version = ChangelogReader.instance_variable_get(:@version)
    changelogs = ChangelogReader.instance_variable_get(:@changelogs)
    expect(version).to be_falsey
    expect(changelogs).to be_falsey
  end
end