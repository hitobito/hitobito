# encoding: utf-8

#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Ics
  class Events

    def generate(events)
      ical = Icalendar::Calendar.new
      ical_events = events.map { |event| generate_ical_from_event_dates(event) }.flatten
      ical_events.each { |event| ical.add_event(event) }
      ical.to_ical
    end

    def generate_ical_from_event_dates(event)
      event.dates.map do |event_date|
        generate_ical_from_event_date(event_date, event)
      end
    end

    def generate_ical_from_event_date(event_date, event)
      Icalendar::Event.new.tap do |ical_event|
        ical_event.dtstart = datetime_to_ical(event_date.start_at)
        ical_event.dtend   = datetime_to_ical(event_date.finish_at)
        ical_event.summary = "#{event.name}: #{event_date.label}"
        ical_event.location = event_date.location || event.location
        ical_event.description = event.description
        ical_event.contact = event.contact && event.contact.to_s
      end
    end

    def datetime_to_ical(datetime)
      return unless datetime.respond_to?(:strftime)
      if Duration.date_only?(datetime)
        return Icalendar::Values::Date.new(datetime.strftime(Icalendar::Values::Date::FORMAT))
      end
      Icalendar::Values::DateTime.new(datetime.strftime(Icalendar::Values::DateTime::FORMAT))
    end
  end
end
