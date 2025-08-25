#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveOldParticipationsUniqueIndex < ActiveRecord::Migration[7.1]
  def change
    # We have added a new polymorphic index in MakeParticipationPersonPolymorphic
    # so this old one is not needed anymore.
    remove_index :event_participations, name: "index_event_participations_on_event_id_and_participant_id", if_exists: true
    # The column person_id was renamed to participant_id. Rails tries to rename
    # indexes as well, but in some cases (on SWW INT) this did not happen for some reason.
    # To be safe, we delete both name variants with an IF EXISTS.
    remove_index :event_participations, name: "index_event_participations_on_event_id_and_person_id", if_exists: true
  end
end
