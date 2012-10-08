# encoding: utf-8

class EventDecorator < ApplicationDecorator
  decorates :event


  def label
    "#{kind.label}<br/>#{h.muted(group.name)}".html_safe
  end

  def dates_info
    model.dates.map { |date| format_event_date(date) }.join('<br/>').html_safe
  end

  def booking_info
    "#{participant_count} von #{maximum_participants}"
  end
  
  def possible_role_links
    model.class.role_types.map do |type|
      unless type.restricted
        link = h.new_event_role_path(self, event_participation: { type: type.sti_name})
        h.link_to(type.model_name.human, link)
      end
    end.compact
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
