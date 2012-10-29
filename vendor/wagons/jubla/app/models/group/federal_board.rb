# Bundesleitung
class Group::FederalBoard < Group
  
  
  class Member < Jubla::Role::Member
    self.permissions = [:admin, :layer_full, :contact_data, :login, :qualify]
    
    attr_accessible :employment_percent
  end
  
  roles Member
  
end
