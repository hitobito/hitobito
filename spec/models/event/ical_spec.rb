# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Event do
  let(:event) { events(:top_course) }
  let(:event_date) { event.dates.first }

  describe '#ical_events' do
    subject(:ical) { event.ical_events }

    it 'contains the event dates' do
      is_expected.to all(be_a(Icalendar::Event))
      expect(ical.first).to have_attributes(
        dtstart: event_date.start_at ,
        dtend: event_date.finish_at,
        summary: "#{event.name}: #{event_date.label}"
      )
      #expect(ical.to_ical).to include('VCALENDAR', 'DTSTART', 'DTEND', 'SUMMARY')
    end
  end
end
