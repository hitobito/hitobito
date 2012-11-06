class Census < ActiveRecord::Base
  
  attr_accessible :year, :start_at, :finish_at
  
  
  def year
    super || Date.today.year
  end
  
  def start_at
    super || Date.today
  end
  
end