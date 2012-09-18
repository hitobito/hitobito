# Verbandsleitung
class Group::OrganizationBoard < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data, :login]
  end
  
  class Treasurer < Jubla::Role::Treasurer
    self.permissions = [:contact_data, :login]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:contact_data, :login]
  end
  
  roles Leader, Treasurer, Member
  
end