module Event::PreloadAllDates

  def self.extended(base)
    base.do_preload_all_dates
  end
  
  def self.for(records)
    records = Array(records)
    
    # preload dates
    ActiveRecord::Associations::Preloader.new(
      records, 
      [:dates]).run
      
    records
  end
  
  def do_preload_all_dates
    @do_preload_all_dates = true
  end
  
  private
  
  def exec_queries
    records = super
    
    Event::PreloadAllDates.for(records) if @do_preload_all_dates
    
    records
  end
end