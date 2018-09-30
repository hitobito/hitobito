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

    def generate_additional_description_from_event(event)
      con = event.contact
      if con
        con_phone_mail = "\n#{con.person_name}"
        con.phone_numbers.each do |item|
            con_phone_mail += "\n#{item.label}: #{item.number}" if item.public
        end
        con_phone_mail += "\n#{con.email}" if con.email?
        # I did not get the following to work. By importing
        # Rails.application.routes.url_helpers
        # It would run the tests but failed in the development environment.
        # It complained about missing default_url_options[:host] but I have
        # not found a way to set it in a way the application would recognise it.
        #con_phone_mail += event_url(id: event)
        con_phone_mail
      end
    end

    def generate_ical_from_event_date(event_date, event)
      Icalendar::Event.new.tap do |ical_event|
        ical_event.dtstart = datetime_to_ical(event_date.start_at)
        ical_event.dtend = datetime_to_ical(event_date.finish_at)
        ical_event.summary = "#{event.name}: #{event_date.label}"
        ical_event.location = event_date.location || event.location
        ical_event.description = "#{event.description} \n#{generate_additional_description_from_event(event)}"
        ical_event.contact = event.contact && event.contact.to_s
      end
    end

    def datetime_to_ical(datetime)
      return unless datetime.respond_to?(:strftime)
      if Duration.date_only?(datetime)
        Icalendar::Values::Date.new(datetime.strftime(Icalendar::Values::Date::FORMAT))
      else
        Icalendar::Values::DateTime.new(datetime.strftime(Icalendar::Values::DateTime::FORMAT))
      end
    end
  end
end
