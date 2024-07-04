# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ParticipationCleanupAnswersJob < RecurringJob
  run_every 1.day

  private

  def perform_internal
    obsolete_answers.delete_all if cutoff
  end

  def obsolete_answers
    Event::Answer.joins(:participation).where(not_participating_since_cutoff)
  end

  def not_participating_since_cutoff
    Event.select("id")
      .joins(:dates)
      .where("event_dates.start_at > :cutoff OR event_dates.finish_at > :cutoff", cutoff: cutoff)
      .where("event_participations.event_id = events.id").arel.exists.not
  end

  def cutoff
    Settings.event.participations.delete_answers_after_months.then do |number|
      number.months.ago if number
    end
  end
end
