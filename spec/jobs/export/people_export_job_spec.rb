# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::PeopleExportJob do

  subject { Export::PeopleExportJob.new(format, user.id, filter, { household: household, full: full }) }

  let(:user)      { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: group).person }
  let(:filter)    { Person::Filter::List.new(group, user) }
  let(:group)     { groups(:bottom_layer_one) }
  let(:household) { false }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }
    let(:full) { false }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Personen')

      lines = last_email.attachments.first.body.to_s.split("\n")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0].split(';').count).to match(14)
    end

    it 'send exports zipped if larger than 512kb' do
      export = subject.export_file
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      file = last_email.attachments.first
      expect(file.content_type).to match(%r!application/zip!)
      expect(file.content_type).to match(/filename=people_export.zip/)
    end

    it 'zips exports larger than 512kb' do
      10.times { Fabricate(Group::BottomLayer::Member.name.to_sym, group: group) } # create a few entries to make zipping worth it.

      export = subject.export_file
      export_size = export.size
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      file, format = subject.export_file_and_format

      expect(format).to eq :zip
      expect(file.size).to be < export_size
    end

    context 'household' do
      let(:household) { true }

      before do
        user.update(household_key: 1)
        people(:bottom_member).update(household_key: 1)
      end

      it 'and sends email with single line per household' do
        subject.perform
        lines = last_email.attachments.first.body.to_s.split("\n")
        expect(lines.size).to eq(2)
      end
    end
  end

  context 'creates a full CSV-Export' do
    let(:format) { :csv }
    let(:full) { true }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Personen')

      lines = last_email.attachments.first.body.to_s.split("\n")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;.*/)
      expect(lines[0]).to match(/Zusätzliche Angaben;.*/)
      expect(lines[0].split(';').count).not_to match(14)
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }
    let(:full) { false }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Personen')

      file = last_email.attachments.first
      expect(file.content_type).to match(/officedocument.spreadsheetml.sheet/)
      expect(file.content_type).to match(/filename=people_export.xlsx/)
    end
  end

end
