# frozen_string_literal: true

#  Copyright (c) 2017-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::PeopleExportJob do

  subject do
    Export::PeopleExportJob.new(format, user.id, group.id, {}, options: export_options)
  end

  let(:export_options) do
    { household: household, full: full,
      show_related_roles_only: show_related_roles_only,
      filename: filename,
      selection: selection, filename: filename }
  end

  let!(:user)      { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }
  let(:bottom_member)    { people(:bottom_member) }
  let(:group)     { groups(:bottom_layer_one) }
  let(:household) { false }
  let(:selection) { false }
  let(:show_related_roles_only) { false }
  let(:file)      { AsyncDownloadFile.from_filename(filename, format) }
  let(:filename) { AsyncDownloadFile.create_name('people_export', user.id) }
  let(:lines) { file.read.lines }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }
    let(:full) { false }

    it 'and saves it' do
      subject.perform

      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0].split(';').count).to match(15)
    end

    context 'household' do
      let(:household) { true }

      before do
        member.update!(household_key: 1)
        bottom_member.update!(household_key: 1)
      end

      it 'and saves it with single line per household' do
        subject.perform

        expect(lines.size).to eq(2)
      end
    end
    context 'table_display' do
      let(:selection) { true }
      let(:csv) { CSV.parse(file.read, col_sep: Settings.csv.separator.strip, headers: true) }

      let!(:registered_columns) { TableDisplay.table_display_columns.clone }
      let!(:registered_multi_columns) { TableDisplay.multi_columns.clone }

      before do
        TableDisplay.table_display_columns = {}
        TableDisplay.multi_columns = {}
      end

      after do
        TableDisplay.table_display_columns = registered_columns
        TableDisplay.multi_columns = registered_multi_columns
      end

      it 'renders standard columns' do
        subject.perform

        expect(csv.headers.last).not_to eq 'Zusätzliche Angaben'
      end

      it 'appends selected column and renders value' do
        TableDisplay.register_column(Person, TableDisplays::PublicColumn, 'additional_information')
        user.table_display_for(Person).save!
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

      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0]).to match(/Zusätzliche Angaben;.*/)
      expect(lines[0].split(';').count).not_to match(14)
    end

  end

  context 'show related person roles only' do
    let(:format) { :csv }
    let(:full) { true }
    let(:show_related_roles_only) { true }
    let(:role_columns) {   }

    before do
      Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_two), person: bottom_member)
    end

    it 'shows only roles for given group' do
      subject.perform

      expect(lines[1]).not_to match(/Leader Bottom Two/)
      expect(lines[2]).not_to match(/Leader Bottom Two/)
    end

    it 'shows only roles for given people filter' do
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
