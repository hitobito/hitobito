#  Copyright (c) 2012-2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Tabular::People
  class ParticipationsAddress < PeopleAddress
    self.row_class = ParticipationRow

    def people_ids
      @people_ids ||= pluck_ids_from_list(
        "event_participations.participant_id",
        @list.where(participant_type: Person.sti_name)
      )
    end
  end
end
