class Duration < Struct.new(:start_at, :finish_at)
  include StandardHelper
  include ActionView::Helpers::TranslationHelper
  attr_reader :start, :finish


  def to_s
    populate
    start = simple_format(:start)
    finish = simple_format(:finish)
    content = ""
    content << start unless start.blank?
    content << " - " if start.present? and finish.present?
    content << finish unless finish.blank?
    return content
  end

  private
  def populate
    @start = kind(start_at) if start_at
    @finish = kind(finish_at) if finish_at
  end

  def kind(date)
    date.seconds_since_midnight == 0.0 ? :date : :time
  end

  def simple_format(symbol)
    case send(symbol)
    when :date then format_date(symbol)
    when :time then format_date_time(symbol)
    end
  end

  def format_date(symbol)
    if symbol == :finish
      return nil if start_at && start_at.to_date == finish_at.to_date
    end
    value = send("#{symbol}_at".to_sym)
    format(value.to_date)
  end

  def format_date_time(symbol)
    if start == :time && finish == :time
      if (start_at == finish_at)
        return format_date(symbol) if symbol == :finish
      end

      if (start_at.to_date == finish_at.to_date)
        return format(send("#{symbol}_at".to_sym)) if symbol == :finish
      end

      if start_at.to_date != finish_at.to_date
        return format_date(symbol)
      end
    end
    value = send("#{symbol}_at".to_sym)
    format(value.to_date) + " " + format(value)
  end


  def format(date)
    f(date)
  end

end
