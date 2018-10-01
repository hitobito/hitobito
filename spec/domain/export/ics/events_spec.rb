# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Ics::Events do
  let(:event) { events(:top_course) }
  let(:event_date) { event.dates.first }
  let(:export) { described_class.new }
  let(:ical_date_klass) { Icalendar::Values::Date }
  let(:ical_datetime_klass) { Icalendar::Values::DateTime }

  describe '#generate_ical_from_event_dates' do
    subject(:ical_events) { export.generate_ical_from_event_dates(event) }

    it 'contains the event dates' do
      is_expected.to all(be_a(Icalendar::Event))
      expect(ical_events.count).to eq(event.dates.count)
    end

    it 'does not fail if contact is set' do
      event.update(contact: people(:top_leader))

      people(:top_leader).phone_numbers.create!(label: 'showme', number: 'Bar', public: true)
      people(:top_leader).phone_numbers.create!(label: 'notme', number: 'Bar', public: false)

      is_expected.to all(be_a(Icalendar::Event))
      expect(subject.first.contact.first.value).to eq 'Top Leader'
      expect(subject.first.description.value).to include "Top Leader"
      expect(subject.first.description.value).to include "top_leader@example.com"
      expect(subject.first.description.value).to include "showme"
      expect(subject.first.description.value).not_to include "notme"
    end
  end

  describe '#generate_ical_from_event_date' do
    subject(:ical_event) { export.generate_ical_from_event_date(event_date, event) }

    context 'with only a start date' do
      let(:event_date) do
        Event::Date.new(event: event, start_at: Time.zone.local(2018, 5, 19), location: 'testlocation')
      end

      it do
        expect(ical_event.dtstart).to be_a(ical_date_klass)
        expect(ical_event.dtstart.value_ical).to eq(event_date.start_at.strftime(ical_date_klass::FORMAT))
        expect(ical_event.dtend).to be nil
        expect(ical_event.summary.to_s).to eq("#{event.name}: #{event_date.label}")
        expect(ical_event.location.to_s).to eq(event_date.location)
      end
    end

    context 'with a start datetime and an end datetime' do
      let(:event_date) do
        Event::Date.new(
          event: event,
          start_at: Time.zone.local(2018, 5, 19, 12, 0),
          finish_at: Time.zone.local(2018, 5, 21, 16, 0)
        )
      end

      it do
        expect(ical_event.dtstart).to be_a(ical_datetime_klass)
        expect(ical_event.dtstart.value_ical).to eq(event_date.start_at.strftime(ical_datetime_klass::FORMAT))
        expect(ical_event.dtend).to be_a(ical_datetime_klass)
        expect(ical_event.dtend).to eq(event_date.finish_at.strftime(ical_datetime_klass::FORMAT))
      end
    end
  end

  describe '#datetime_to_ical' do
    subject { export.datetime_to_ical(datetime) }

    context 'with fullday event' do
      let(:datetime) { Time.zone.local(2018, 5, 19) }
      it { is_expected.to be_a(ical_date_klass) }
    end

    context 'with timed event' do
      let(:datetime) { Time.zone.local(2018, 5, 19, 12, 15) }
      it { is_expected.to be_a(ical_datetime_klass) }
    end

    context 'with nil' do
      let(:datetime) { nil }
      it { is_expected.to be nil }
    end
end

  describe '#generate' do
    subject(:ical_events) { export.generate([event, event]) }

    it do
      is_expected.to include('BEGIN:VCALENDAR')
      is_expected.to include('VERSION:2.0')
      is_expected.to include('BEGIN:VCALENDAR')
    end
  end
end
