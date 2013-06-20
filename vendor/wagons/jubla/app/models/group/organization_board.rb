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

  class Alumnus < Jubla::Role::Alumnus
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Treasurer, Member, Alumnus, DispatchAddress, GroupAdmin, External
  
end
