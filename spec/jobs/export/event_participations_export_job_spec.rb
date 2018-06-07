# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::EventParticipationsExportJob do

  subject { Export::EventParticipationsExportJob.new(format,
                                                     user.id,
                                                     event.id,
                                                     event_participation_filter,
                                                     details) }

  let(:participation)              { event_participations(:top) }
  let(:user)                       { participation.person }
  let(:event)                      { participation.event }
  let(:params)                     { { filter: 'all' } }
  let(:details)                    { nil }
  let(:event_participation_filter) { Event::ParticipationFilter.new(event, user, params) }

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Event-Teilnehmer')

      lines = last_email.attachments.first.body.to_s.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/Vorname;Nachname;Übername;Firmenname;.*/)
      expect(lines[0].split(';').count).to match(14)
    end

    it 'send exports zipped if larger than 512kb' do
      export = subject.export_file
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      file = last_email.attachments.first
      expect(file.content_type).to match(%r{application/zip})
      expect(file.content_type).to match(/filename=event_participations_export.zip/)
    end

    it 'zips exports larger than 512kb' do
      20.times { Fabricate(:event_participation) }
      expect_any_instance_of(Export::EventParticipationsExportJob)
        .to receive(:entries)
        .at_least(1).times
        .and_return(Event::Participation.all)

      export = subject.export_file
      export_size = export.size
      expect(export).to receive(:size) { 1.megabyte } # trigger compression by faking the size

      file, format = subject.export_file_and_format

      expect(format).to eq :zip
      expect(file.size).to be < export_size
    end
  end

  context 'creates a full CSV-Export' do
    let(:format) { :csv }
    let(:details) { true }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Event-Teilnehmer')

      lines = last_email.attachments.first.body.to_s.split("\n")
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/Vorname;Nachname;Firmenname;Übername.*/)
      expect(lines[0]).to match(/;Bemerkungen \(Allgemeines.*/)
      expect(lines[0].split(';').count).to match(17)
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }

    it 'and sends it via mail' do
      expect do
        subject.perform
      end.to change { ActionMailer::Base.deliveries.size }.by 1

      expect(last_email.subject).to eq('Export der Event-Teilnehmer')

      file = last_email.attachments.first
      expect(file.content_type).to match(/officedocument.spreadsheetml.sheet/)
      expect(file.content_type).to match(/filename=event_participations_export.xlsx/)
    end
  end

end
