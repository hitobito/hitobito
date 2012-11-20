# encoding: UTF-8
module Event::ParticipationsHelper
  def event_attr_with_break(attr)
    str = parent.send(attr) + tag(:br)
    str.html_safe
  end

  def edit_person_path
    person = entry.person
    group = person.groups.first
    edit_group_person_path(group,person)
  end

  def role_filter_links
    content = role_filters.map do |key, value| 
      filter = key == :all ? {} : { filter: key }
      link = event_participations_path(parent, filter)
      link_to(value, link)
    end
  end
  
  def role_filter_title
    choices = role_filters
    key = choices.keys.map(&:to_s).find { |key| params[:filter].to_s == key }
    key ||= choices.keys.first
    choices[key.to_sym]
  end

  def role_filters
    role_labels = entry.event.participation_role_labels
    Event::ParticipationsController::FILTER.merge(role_labels)
  end
end
