class Duration < Struct.new(:start_at, :finish_at)
  include StandardHelper
  include ActionView::Helpers::TranslationHelper

  def to_s
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
    f(date)
  end

end
