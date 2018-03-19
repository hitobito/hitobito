# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Ics
  class Events

    def generate(events)
      ical = Icalendar::Calendar.new
      ical_events = events.map { |event| generate_ical_events(event) }.flatten
      ical_events.each { |event| ical.add_event(event) }
      ical.to_ical
    end

    def generate_ical_events(event)
      event.dates.map do |event_date|
        Icalendar::Event.new.tap do |ical_event|
          ical_event.dtstart = event_date.start_at
          ical_event.dtend   = event_date.finish_at
          ical_event.summary = "#{event.name}: #{event_date.label}"
          ical_event.location = event_date.location || event.location
          ical_event.description = event.description
          ical_event.contact = event.contact && event.contact.to_s
        end
      end
    end
  end
end
