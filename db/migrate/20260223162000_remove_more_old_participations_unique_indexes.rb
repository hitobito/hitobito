#  Copyright (c) 2025, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class RemoveMoreOldParticipationsUniqueIndexes < ActiveRecord::Migration[7.1]
  def up
    # We have some old index names with numbers in them, so matching by name in
    # RemoveOldParticipationsUniqueIndex was not enough to get all of them.
    # Try removing by columns instead.

    # We have added a new polymorphic index in MakeParticipationPersonPolymorphic
    # so this old one is not needed anymore.
    remove_index :event_participations, column: [:event_id, :participant_id], if_exists: true
  end
end
