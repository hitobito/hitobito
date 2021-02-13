# encoding: utf-8

#  Copyright (c) 2012-2020, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Ics
  class Events

    include Rails.application.routes.url_helpers

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

    def event_description(event)
      return event.description unless event.contact

      [
        event.description, "",
        event.contact.person_name,
        event.contact.phone_numbers.map { |pn| "#{pn.label}: #{pn.number}" if pn.public },
        event.contact.email, "",
        url(event)
      ].flatten.compact.join("\n")
    end

    def url(event)
      group_event_url(group_id: event.groups.first.id, id: event.id, host: ENV["RAILS_HOST_NAME"])
    end

    def generate_ical_from_event_date(event_date, event)
      Icalendar::Event.new.tap do |ical_event|
        ical_event.dtstart = datetime_to_ical(event_date.start_at)
        ical_event.dtend = finish_at_to_ical(event_date.finish_at)
        ical_event.summary = event.name
        ical_event.summary += ": #{event_date.label}" unless event_date.label.blank?
        ical_event.location = event_date.location || event.location
        ical_event.description = event_description(event)
        ical_event.contact = event.contact && event.contact.to_s
      end
    end

    def finish_at_to_ical(finish_at)
      return if finish_at.nil?
      if Duration.date_only?(finish_at)
        # For all-day events, the iCalendar standard requires exclusive end dates.
        # Since we interpret 0:00 as all-day, we need to add 1 day to get the real end date.
        datetime_to_ical(finish_at + 1.day)
      else
        datetime_to_ical(finish_at)
      end
    end

    def datetime_to_ical(datetime)
      return if datetime.nil?
      if Duration.date_only?(datetime)
        Icalendar::Values::Date.new(datetime)
      else
        Icalendar::Values::DateTime.new(datetime.utc, tzid: "UTC")
      end
    end
  end
end
