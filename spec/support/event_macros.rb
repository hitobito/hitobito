module EventMacros

  def set_start_finish(event, start_at, finish_at)
    event.dates.clear
    event.dates.build(start_at: start_at, finish_at: finish_at) 
    event.save
  end

  def set_start_dates(event, *dates)
    event.dates.clear
    dates.map! {|date| date.class == String ? Time.zone.parse(date) : date } 
    dates.each { |date| event.dates.build(start_at: date) } 
    event.save
  end
end
