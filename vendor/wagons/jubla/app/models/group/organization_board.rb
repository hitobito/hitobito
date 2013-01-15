# Verbandsleitung
class Group::OrganizationBoard < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data]
  end
  
  class Treasurer < Jubla::Role::Treasurer
    self.permissions = [:contact_data, :group_read]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:contact_data, :group_read]
  end
  
  roles Leader, Treasurer, Member
  
end