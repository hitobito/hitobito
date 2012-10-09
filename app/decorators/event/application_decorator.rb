# encoding: utf-8
class Event::ApplicationDecorator < ApplicationDecorator
  decorates 'event/application'
  decorates_association :event

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link
    link = h.link_to(kind.label, h.event_participation_path(event,participation))
    safe_join([link, h.muted(group.name)], h.tag(:br))
  end
end
  
