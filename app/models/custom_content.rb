class CustomContent < ActiveRecord::Base
  attr_accessible :body, :subject
  
  class << self
    def get(key)
      find_by_key(key)
    end
  end
  
  def to_s
    label
  end
end
