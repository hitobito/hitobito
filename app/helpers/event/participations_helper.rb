# encoding: UTF-8
module Event::ParticipationsHelper

  def edit_person_path
    person = entry.person
    group = person.groups.first
    edit_group_person_path(group,person)
  end

  def role_filter_links
    content = Event::ParticipationsController::FILTER.map do |key, value| 
      filter = key == :all ? {} : { filter: key }
      link = event_participations_path(entry.event, entry, filter)
      link_to(value, link)
    end
  end
  def role_filter_title
    choices = Event::ParticipationsController::FILTER
    key = choices.keys.map(&:to_s).find { |key| params[:filter].to_s == key }
    key ||= choices.keys.first
    choices[key.to_sym]
  end
end
