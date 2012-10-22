# encoding: utf-8

class EventDecorator < ApplicationDecorator
  decorates :event


  def used_attribute(attr)
    model.class.attr_used?(attr)
  end

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
    safe_join(dates, h.tag(:br)) { |date| format_event_date(date) }
  end
  
  def dates_full
    safe_join(dates, h.tag(:br)) { |date| safe_join([format_event_date(date), h.muted(date.label)], ' ') }
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
  
  private
  
  def format_event_date(date)
    start_at, finish_at = date.start_at, date.finish_at
    return format(start_at.to_date) if start_at && finish_at.nil? # single date only
    return format(finish_at.to_date) if start_at.nil? && finish_at # single date only

    # both set, different dates
    if start_at.to_date != finish_at.to_date
      return "#{format(start_at.to_date)} - #{format(finish_at.to_date)}".strip
    end

    # both set, same dates, no time
    if start_at.to_date == finish_at.to_date && (start_at == start_at.midnight && 
                                                 finish_at == finish_at.midnight)
      return "#{format(start_at.to_date)}"
    end

    # both set, same dates, start_at has time
    if start_at.to_date == finish_at.to_date && (start_at != start_at.midnight && 
                                                 finish_at == finish_at.midnight)
      return "#{format(start_at.to_date)} #{format(start_at)}"
    end


    # both set, same dates, finish_at has time
    if start_at.to_date == finish_at.to_date && (start_at == start_at.midnight && 
                                                 finish_at != finish_at.midnight)
      return "#{format(start_at.to_date)} #{format(start_at)}"
    end

    # both set, same dates, both have times, they are the same
    if start_at == finish_at
      return "#{format(start_at.to_date)} #{format(start_at)}"
    end

    # both set, same dates, both have times, they are different
    if start_at.to_date == finish_at.to_date && (start_at != start_at.midnight && 
                                                 finish_at != finish_at.midnight)
      return "#{format(start_at.to_date)} #{format(start_at)} - #{format(finish_at)}"
    end

  end

  def format(date)
    #date = date.to_date if date == date.midnight
    h.f(date)
  end
end
