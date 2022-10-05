# encoding: utf-8

#  Copyright (c) 2018-2022, Schweizer Blasmusikverband. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::SubgroupsExportJob do

  subject { Export::SubgroupsExportJob.new(user.id, group.id, filename: filename) }

  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:year)  { 2012 }
  let(:file)  { AsyncDownloadFile.from_filename(filename, :csv) }
  let(:filename) { AsyncDownloadFile.create_name('subgroups_export', user.id) }

  context 'creates a CSV-Export' do

    it 'and saves it' do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(10)
      expect(lines[0]).to match(/^Id;Elterngruppe;Name;.*/)
      expect(lines[1]).to match(/^#{group.id};;Top;.*/)
      expect(lines[2]).to match(/^#{groups(:bottom_layer_one).id};#{group.id};Bottom One;.*/)
    end
  end

end
