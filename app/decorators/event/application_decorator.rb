# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Event::ApplicationDecorator < ::ApplicationDecorator
  decorates 'event/application'
  
  decorates_association :event
  decorates_association :priority_1
  decorates_association :priority_2
  decorates_association :priority_3

  delegate :dates_info, :dates_full, :kind, :group, to: :event

  def labeled_link(group = nil)
    group ||= event.groups.first
    event.labeled_link(h.group_event_participation_path(group, event, participation),
                       can?(:show, participation))
  end
  
  def contact
    c = model.contact
    c ? "#{c.class.base_class.name}Decorator".constantize.decorate(c) : nil
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
    confirmation_badge(*confirmation_fields)
  end
  
  def confirmation_label
    label, css, desc = confirmation_fields
    confirmation_badge(label, css, desc) +
    " Kursfreigabe #{desc}"
  end
  
  def confirmation_badge(label, css, desc)
    content_tag(:span, label.html_safe, class: "badge badge-#{css}", title: "Kursfreigabe #{desc}")
  end
  
  private
  
  
  
  def confirmation_fields
    if approved?
      %w(&#x2713; success bestätigt)
    elsif rejected?
      %w(&#x00D7; important abgelehnt)
    else
      %w(? warning ausstehend)
    end
  end

end
  
