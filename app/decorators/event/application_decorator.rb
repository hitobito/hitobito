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
  
  def priority(event)
    prio = model.priority(event)
    if prio
      prio = "Prio #{prio}"
    else
      prio = waiting_list? ? 'Warteliste' : nil
    end
    content_tag(:span, prio, class: 'badge') if prio
  end
  
  def confirmation
    label, css, desc = if approved?
      %w(&#x2713; success bestätigt)
    elsif rejected?
      %w(&#x00D7; important abgelehnt)
    else
      %w(? warning ausstehend)
    end
    
    content_tag(:span, label, class: "badge badge-#{css}", title: "Kursfreigabe #{desc}")
  end
  

end
  
