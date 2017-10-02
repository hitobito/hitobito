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

  describe '#generate_ical_events' do
    subject(:ical_events) { export.generate_ical_events(event) }

    it 'contains the event dates' do
      is_expected.to all(be_a(Icalendar::Event))
      expect(ical_events.count).to eq(event.dates.count)
      expect(ical_events.first).to have_attributes(
        dtstart: event_date.start_at ,
        dtend: event_date.finish_at,
        summary: "#{event.name}: #{event_date.label}"
      )
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
