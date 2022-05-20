# encoding: utf-8

#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::PeopleExportJob do

  subject { Export::PeopleExportJob.new(format, user.id, group.id, {}, { household: household, full: full, selection: selection, filename: 'people_export' }) }

  let(:user)      { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }
  let(:group)     { groups(:bottom_layer_one) }
  let(:household) { false }
  let(:selection) { false }
  let(:file)      { AsyncDownloadFile.maybe_from_filename('people_export', user.id, format) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }
    let(:full) { false }

    it 'and saves it' do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0].split(';').count).to match(15)
    end

    context 'household' do
      let(:household) { true }

      before do
        user.update(household_key: 1)
        people(:bottom_member).update(household_key: 1)
      end

      it 'and saves it with single line per household' do
        subject.perform
        lines = file.read.lines
        expect(lines.size).to eq(2)
      end
    end

    context 'table_display' do
      let(:selection) { true }
      let(:csv) { CSV.parse(file.read, col_sep: Settings.csv.separator.strip, headers: true) }

      it 'renders standard columns' do
        subject.perform
        expect(csv.headers.last).not_to eq 'Zusätzliche Angaben'
      end

      it 'appends selected column and renders value' do
        user.table_display_for(group).update(selected: %w(additional_information))
        Person.update_all(additional_information: 'bla bla')
        subject.perform
        expect(csv.headers.last).to eq 'Zusätzliche Angaben'
        expect(csv.first['Zusätzliche Angaben']).to eq 'bla bla'
      end
    end
  end

  context 'creates a full CSV-Export' do
    let(:format) { :csv }
    let(:full) { true }

    it 'and saves it' do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0]).to match(/Zusätzliche Angaben;.*/)
      expect(lines[0].split(';').count).not_to match(14)
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }
    let(:full) { false }

    it 'and saves it' do
      subject.perform
      expect(file.generated_file).to be_attached
    end
  end

end
