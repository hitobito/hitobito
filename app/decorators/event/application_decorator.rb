class Event::ApplicationDecorator < ApplicationDecorator
  decorates 'event/application'
  decorates_association :event

  def labeled_link
    link = h.link_to(event.kind, h.event_participation_path(event, model))
    safe_join([link, h.muted(event.group.name)], h.tag(:br))
  end

  def dates_info
    event.dates_info
  end

end
