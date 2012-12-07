# encoding: UTF-8
module Event::ParticipationsHelper
  
  def event_attr_with_break(attr)
    str = parent.send(attr) + tag(:br)
    str.html_safe
  end

  def role_filter_links
    content = role_filters.map do |key, value|
      filter = key == :all ? {} : { filter: key }
      link = group_event_participations_path(@group, @event, filter)
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
    Event::ParticipationsController::FILTER.merge(event_role_filters)
  end

  def event_role_filters
    links = {}
    labels = entry.event.participation_role_labels
    labels.each { |l| links[l.to_sym] = l }
    links
  end

  def participations_csv_export_links
    csv_path = params.merge(format: :csv)
    csv_links = [link_to('Adressliste', csv_path),
                 link_to('Alle Angaben', csv_path.merge(details: true))]
    if can?(:show_details, entries.first)
      dropdown_button('CSV Export', csv_links, :download)
    else
      link_to('CSV Export', csv_links.first)
    end
  end
end
