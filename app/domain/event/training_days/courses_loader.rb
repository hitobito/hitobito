# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of hitobito and licensed under the
#  Affero General Public License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.

module Event::TrainingDays
  class CoursesLoader
    def initialize(person_id, role, qualification_kind_ids, start_date, end_date)
      @person_id = person_id
      @role = role
      @qualification_kind_ids = qualification_kind_ids
      @start_date = start_date.midnight
      @end_date = end_date.end_of_day
    end

    def load
      Event::Course
        .between(@start_date, @end_date)
        .includes(:dates, kind: {event_kind_qualification_kinds: :qualification_kind})
        .joins(:participations, kind: {event_kind_qualification_kinds: :qualification_kind})
        .where(event_participations: {qualified: true, person: @person_id})
        .where(event_kind_qualification_kinds: {
          qualification_kind_id: @qualification_kind_ids,
          category: :prolongation,
          role: @role
        })
        .order("event_dates.start_at DESC")
        .distinct
    end
  end
end
