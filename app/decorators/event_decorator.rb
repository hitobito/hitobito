# encoding: utf-8

class EventDecorator < ApplicationDecorator
  decorates :event
  decorates_association :contact

  def label
    safe_join([name, label_detail], h.tag(:br))
  end

  def labeled_link(url = nil)
    url ||= h.group_event_path(group_id, model)
    safe_join([h.link_to(name, url), h.muted(model.label_detail)], h.tag(:br))
  end

  def simple_link(url = nil)
    url ||= h.group_event_path(group_id, model)
    h.link_to(name, url)
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

  def preconditions 
    model.kind_of?(Event::Course) &&  kind.preconditions.map(&:label)
  end
  
  def state_translated(state = model.state)
    h.t("activerecord.attributes.event/course.states.#{state}") if state
  end

  def state_collection
    possible_states.collect {|s| Struct.new(:id, :to_s).new(s, state_translated(s)) }
  end
    
  def can_create_participation?
    p = participations.new
    p.person = current_user
    can?(:new, p)
  end
  
  def description
    h.simple_format(model.description) if model.description?
  end

  def description_short
    if model.description?
      h.simple_format(h.truncate(model.description, length: 60))
    end
  end
  
  def location
    h.simple_format(model.location) if model.location?
  end

  def with_br(*attrs)
    values = attrs.map do |attr|
      send(attr).presence
    end.compact
    safe_join(values, h.tag(:br))
  end
  
end
