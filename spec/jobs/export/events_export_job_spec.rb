# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::EventsExportJob do

  subject { Export::EventsExportJob.new(format, user.id, nil, year, group) }

  let(:user)  { people(:top_leader) }
  let(:group) { groups(:top_layer) }
  let(:year)  { 2012 }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
    Fabricate(:event)
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Anlässe')

      lines = last_email.attachments.first.body.to_s.split("\n")
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Name;Organisatoren;Beschreibung;.*/)
      expect(lines[0].split(';').count).to match(34)
    end

    it 'send exports zipped if larger than 512kb' do
      export = subject.export_file
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      file = last_email.attachments.first
      expect(file.content_type).to match(%r{application/zip})
      expect(file.content_type).to match(/filename=events_export.zip/)
    end

    it 'zips exports larger than 512kb' do
      export = subject.export_file
      export_size = export.size
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      file, format = subject.export_file_and_format

      expect(format).to eq :zip
      expect(file.size).to be < export_size
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Anlässe')

      file = last_email.attachments.first
      expect(file.content_type).to match(/officedocument.spreadsheetml.sheet/)
      expect(file.content_type).to match(/filename=events_export.xlsx/)
    end
  end

end
