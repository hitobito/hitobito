module Jubla::Event::Course
  extend ActiveSupport::Concern

  
  included do
    self.participation_types += [Participation::Advisor]
  end
  
  
  module Participation
    class Advisor < ::Event::Participation
     
      self.permissions = [:contact_data]
      self.restricted = true
      self.affiliate = true
    
    end
  end
  
end