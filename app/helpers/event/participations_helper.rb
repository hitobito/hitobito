# encoding: UTF-8
module Event::ParticipationsHelper
  
  def event_attr_with_break(attr)
    str = parent.send(attr) + tag(:br)
    str.html_safe
  end

  def participations_filter_navigation
    pill_navigation(main_participation_filter_items, event_role_label_filter_links, *custom_role_filter_label)
  end

  private

  def main_participation_filter_items
    predefined = Event::ParticipationsController::FILTER.with_indifferent_access
    Event::ParticipationsController::FILTER.collect do |key, value|
      active = !role_label_filter_active? && (predefined[params[:filter]] == value || (params[:filter].blank? && predefined.values.first == value))
      pill_item(link_to(value, event_participation_filter_link(key)), active)
    end
  end
  
  def custom_role_filter_label
    if role_label_filter_active?
      [params[:filter], true]
    else
      ['Weitere Ansichten', false]
    end
  end
  
  def role_label_filter_active?
    @event.participation_role_labels.include?(params[:filter])
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
