module NotesHelper

  def note_path(group, note)
    if note.subject.is_a?(Group)
      group_note_path(group_id: note.subject_id, id: note.id)
    else
      group_person_note_path(group_id: group.id, person_id: note.subject_id, id: note.id)
    end
  end

end
