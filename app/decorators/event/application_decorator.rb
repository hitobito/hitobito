class Event::ApplicationDecorator < ApplicationDecorator

  decorates_association :priority_1

  def link
    h.link_to event.label, h.event_application_path(event, model)
  end

  def dates
    event.dates
  end

  private
  def event
    priority_1
  end

end
