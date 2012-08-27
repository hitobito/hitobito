# Bundesleitung
class Group::FederalBoard < Group
  
  
  class Member < ::Role
    self.permissions = [:layer_full, :contact_data, :login]
    
    attr_accessible :employment_percent
  end
  
  roles Member
  
end