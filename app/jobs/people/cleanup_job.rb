# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class People::CleanupJob < RecurringJob
  run_every 1.day

  def perform_internal
    people = People::CleanupFinder.new.run

    people.find_in_batches do |batch|
      batch.each do |person|
        next if ignore_person?(person)

        if event_participation_in_cutoff?(person)
          minimize_person!(person)
        else
          destroy_person!(person)
        end
      end
    end
  end

  def cutoff
    Settings.people.cleanup_cutoff_duration.regarding_event_participations.months.ago
  end

  def event_participation_in_cutoff?(person)
    Event.joins(:participations, :dates)
         .where(participations: { person_id: person.id })
         .where('event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff', cutoff: cutoff)
         .any?
  end

  def ignore_person?(person)
    person.minimized_at.present?
  end

  def minimize_person!(person)
    People::Minimizer.new(person).run
  end

  def destroy_person!(person)
    People::Destroyer.new(person).run
  end
end
