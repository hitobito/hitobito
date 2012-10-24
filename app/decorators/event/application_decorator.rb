# encoding: utf-8
class Event::ApplicationDecorator < ::ApplicationDecorator
  decorates 'event/application'
  
  decorates_association :event
  decorates_association :priority_1
  decorates_association :priority_2
  decorates_association :priority_3

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link
    event.labeled_link(h.event_participation_path(event, participation))
  end
  
  def contact
    c = model.contact
    "#{c.class.base_class.name}Decorator".constantize.decorate(c)
  end
end
  
