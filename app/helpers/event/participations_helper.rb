# encoding: UTF-8
module Event::ParticipationsHelper
  def edit_person_path
    person = entry.person
    group = person.groups.first
    edit_group_person_path(group,person)
  end
end
