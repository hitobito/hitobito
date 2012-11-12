class Duration < Struct.new(:start_at, :finish_at)

  attr_reader :start, :finish

  def to_s(format = :long)
    if start_at && finish_at
      if start_at == finish_at
        format_datetime(start_at)
      elsif start_at.to_date == finish_at.to_date
        "#{format_date(start_at)} #{format_time(start_at)} - #{format_time(finish_at)}"
      else
        if format == :short
          "#{format_date(start_at)} - #{format_date(finish_at)}"
        else
          "#{format_datetime(start_at)} - #{format_datetime(finish_at)}"
        end
      end
    elsif start_at
      format_datetime(start_at)
    elsif finish_at
      format_datetime(finish_at)
    else
      ''
    end
  end
  
  def active?
    if date_only?(start_at) && date_only?(finish_at)
      cover?(Date.today)
    else
      cover?(Time.zone.now)
    end
  end
  
  def cover?(date)
    date.between?(start_at, finish_at)
  end

  private
  
  def format_datetime(value)
    if date_only?(value)
      format_date(value)
    else
      "#{format_date(value)} #{format_time(value)}"
    end
  end
  
  def format_time(value)
    I18n.l(value, format: :time)
  end
  
  def format_date(value)
    I18n.l(value.to_date)
  end
  
  def date_only?(value)
    !value.respond_to?(:seconds_since_midnight) || value.seconds_since_midnight.zero?
  end
  
end
