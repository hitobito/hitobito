
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
    Settings.people.cleanup_cutoff_duration.regarding_participations.months.ago
  end

  def event_participation_in_cutoff?(person)
    Event.joins(:participations, :dates)
         .where(participations: { person_id: person.id })
         .where('event_dates.start_at > ? OR event_dates.finish_at > ?', cutoff, cutoff) # what if finished_at is nil
  end

  def ignore_person?(person)
    person.minimized_at.present?
  end

  def minimize_person!(person)
    People::Minimizer.new(person).run
    person.minimized_at = Time.zone.now
    person.save!
  end

  def destroy_person!(person)
    People::Destroyer.new(person).run
  end
end
