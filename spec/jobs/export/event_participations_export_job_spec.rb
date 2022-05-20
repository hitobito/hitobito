# encoding: utf-8

#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::EventParticipationsExportJob do

  subject { Export::EventParticipationsExportJob.new(format, user.id, event_participation_filter, params.merge(filename: 'event_participation_export')) }

  let(:participation)              { event_participations(:top) }
  let(:user)                       { participation.person }
  let(:other_user)                 { Fabricate(:person, first_name: 'Other', last_name: 'Member', household_key: 1) }
  let(:event)                      { participation.event }

  let(:params)                     { { filter: 'all' } }
  let(:event_participation_filter) { Event::ParticipationFilter.new(event.id, user, params) }

  let(:file) do
    AsyncDownloadFile
      .maybe_from_filename(subject.filename, user.id, format)
  end

  before do
    SeedFu.quiet = true
    SeedFu.seed [Rails.root.join('db', 'seeds')]

    other_participation = Event::Participation.create(event: event, active: true, person: other_user)
    Event::Role::Participant.create(participation: other_participation)
  end

  context 'creates a CSV-Export' do
    let(:format) { :csv }

    it 'and saves it' do
      subject.perform

      lines = file.read.lines

      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;Übername;Firmenname;.*/)
      expect(lines[0].split(';').count).to match(15)
    end
  end

  context 'creates a full CSV-Export' do
    let(:format) { :csv }
    let(:params) { { details: true } }

    it 'and saves it' do
      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(3)
      expect(lines[0]).to match(/Vorname;Nachname;Firmenname;Übername.*/)
      expect(lines[0]).to match(/;Bemerkungen.*/)
      expect(lines[0].split(';').count).to match(21)
    end
  end

  context 'creates a household export' do
    let(:format) { :csv }
    let(:params) { { household: true } }

    it 'and saves it' do
      user.update(household_key: 1)
      other_user.update(household_key: 1)

      subject.perform

      lines = file.read.lines
      expect(lines.size).to eq(2)
      expect(lines[0]).to match(/Name;Adresse;PLZ;.*/)
      expect(lines[1]).to match(/Bottom und Other Member.*/)
    end
  end

  context 'creates an Excel-Export' do
    let(:format) { :xlsx }

    it 'and saves it' do
      subject.perform
      expect(file.generated_file).to be_attached
    end
  end

end
