# frozen_string_literal: true

#  Copyright (c) 2023, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationCleanupJob < RecurringJob
  run_every 1.day

  def perform_internal
    clean_participations(participations_to_cleanup)
  end

  def clean_participations(participations)
    participations.update_all(additional_information: nil)
  end

  def participations_to_cleanup
    Event::Participation.where(not_participating_since_cutoff)
  end

  def not_participating_since_cutoff
    Event.joins(:dates)
         .where('event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff', cutoff: cutoff)
         .where('event_participations.event_id = events.id').arel.exists.not
  end

  def cutoff
    Settings.event.participations.delete_additional_information_after_months.months.ago
  end
end
