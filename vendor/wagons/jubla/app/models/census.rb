class Census < ActiveRecord::Base
  
  attr_accessible :year, :start_at, :finish_at
  
  after_initialize :set_defaults
  
  validates :start_at, presence: true
  
  class << self
    # The last census defined (may be the current one)
    def last
      order("start_at DESC").first
    end
    
    # The currently active census
    def current
      where('start_at <= ?', Date.today).order("start_at DESC").first
    end
  end

  def to_s
    year
  end

  private
  
  def set_defaults
    if new_record?
      self.start_at  ||= Date.today
      self.year      ||= start_at.year
      self.finish_at ||= Date.new(year, 
                                  Settings.census.default_finish_month, 
                                  Settings.census.default_finish_day)
    end
  end
end