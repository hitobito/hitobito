# encoding: utf-8

class EventDecorator < ApplicationDecorator
  decorates :event


  def label
    safe_join([name, label_detail], h.tag(:br))
  end
  
  def labeled_link(url = nil)
    url ||= h.group_event_path(group, model)
    safe_join([h.link_to(name, url), label_detail], h.tag(:br))
  end
  
  def label_detail
    h.muted("#{kind.short_name} #{number} #{group.name}")
  end

  def dates_info    
    safe_join(dates, h.tag(:br)) { |date| date.duration }
  end
  
  def dates_full
    safe_join(dates, h.tag(:br)) { |date| safe_join([date.duration, h.muted(date.label)], ' ') }
  end

  def booking_info
    info = participant_count.to_s
    info << " von #{maximum_participants}" if maximum_participants.to_i > 0
    info
  end
  
  def possible_role_links
    klass.role_types.map do |type|
      unless type.restricted
        link = h.new_event_role_path(self, event_role: { type: type.sti_name})
        h.link_to(type.model_name.human, link)
      end
    end.compact
  end
  
  def state
    h.t("activerecord.attributes.event/course.states.#{model.state}") if model.state
  end
  
  def can_create_participation?
    p = participations.new
    p.person = current_user
    can?(:new, p)
  end
  
end
