# frozen_string_literal: true

#  Copyright (c) 2017-2021, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NotesHelper

  def note_path(note, group_id)
    case note.subject
    when Group
      group_note_path(group_id: note.subject_id, id: note.id)
    when Person
      group_person_note_path(group_id: group_id, person_id: note.subject_id, id: note.id)
    end
  end

end
