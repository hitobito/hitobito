class Census < ActiveRecord::Base
  
  attr_accessible :year, :start_at, :finish_at
  
  validates :start_at, presence: true
  
  class << self
    def last
      order("start_at DESC").first
    end
  end
  
  def year
    super || Date.today.year
  end
  
  def start_at
    super || Date.today
  end
  
end