#  Copyright (c) 2012-2015, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::EventQueries
  attr_reader :person

  def initialize(person)
    @person = person
  end

  def pending_applications
    person.event_applications
      .merge(Event::Participation.pending)
      .merge(Event::Participation.upcoming)
      .includes(event: [:groups])
      .joins(event: :dates)
      .select("event_applications.*", "event_dates.start_at")
      .order("event_dates.start_at")
      .distinct.tap do |applications|
      Event::PreloadAllDates.for(applications.collect(&:event))
    end
  end

  def unordered_upcoming_events
    person.
      events.
      upcoming.
      merge(Event::Participation.active).
      merge(Event::Participation.upcoming).
      includes(:groups).
      select("events.*", "event_dates.start_at").
      preload_all_dates
  end

  def upcoming_events
    Event.select("*").from(
      unordered_upcoming_events
    ).order_by_date
  end

  def alltime_participations
    Event::Participation.select("*").from(
      person
        .event_participations
        .active
        .joins(event: :dates)
        .select("event_participations.*", "event_dates.start_at")
        .distinct_on(:id)
        .includes(:roles, event: [:translations, :dates, :groups])
    ).order(:start_at).tap do |applications|
      Event::PreloadAllDates.for(applications.collect(&:event))
    end
  end
end
