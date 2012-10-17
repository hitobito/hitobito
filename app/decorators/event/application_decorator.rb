# encoding: utf-8
class Event::ApplicationDecorator < ApplicationDecorator
  decorates 'event/application'
  decorates_association :event

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link
    event.labeled_link(h.event_participation_path(event, participation))
  end
end
  
