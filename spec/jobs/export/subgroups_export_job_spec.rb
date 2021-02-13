# encoding: utf-8

#  Copyright (c) 2018, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "spec_helper"

describe Export::SubgroupsExportJob do
  subject { Export::SubgroupsExportJob.new(user.id, group.id, filename: "subgroups_export") }

  let(:user) { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:year) { 2012 }
  let(:filepath) { AsyncDownloadFile::DIRECTORY.join("subgroups_export") }

  context "creates a CSV-Export" do
    it "and saves it" do
      subject.perform

      lines = File.readlines("#{filepath}.csv")
      expect(lines.size).to eq(10)
      expect(lines[0]).to match(/^Id;Elterngruppe;Name;.*/)
      expect(lines[1]).to match(/^#{group.id};;Top;.*/)
      expect(lines[2]).to match(/^#{groups(:bottom_layer_one).id};#{group.id};Bottom One;.*/)
    end
  end
end
