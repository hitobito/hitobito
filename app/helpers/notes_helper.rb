# encoding: utf-8

#  Copyright (c) 2017, Dachverband Schweizer Jugendparlamente. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module NotesHelper
  def note_path(group, note)
    if note.subject.is_a?(Group)
      group_note_path(group_id: note.subject_id, id: note.id)
    else
      group_person_note_path(group_id: group.id, person_id: note.subject_id, id: note.id)
    end
  end
end
