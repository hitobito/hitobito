# encoding: UTF-8
module Event::ParticipationsHelper
  
  def event_attr_with_break(attr)
    str = parent.send(attr) + tag(:br)
    str.html_safe
  end

  def role_filter_links
    label_links = event_role_label_filter_links
    if label_links.present?
      event_role_filter_links + [nil] + label_links
    else
      event_role_filter_links
    end
  end
  
  def role_filter_title
    filter = params[:filter]
    if @event.participation_role_labels.include?(filter)
      filter
    else
      predefined = Event::ParticipationsController::FILTER.with_indifferent_access
      predefined[filter] || predefined.values.first
    end
  end

  private
  
  def event_role_filter_links
    Event::ParticipationsController::FILTER.collect do |key, value|
      link_to(value, event_participation_filter_link(key))
    end
  end
  
  def event_role_label_filter_links
    @event.participation_role_labels.collect do |label|
      link_to(label, event_participation_filter_link(label))
    end
  end

  def event_participation_filter_link(filter)
    group_event_participations_path(@group, @event, filter: filter)
  end
end
