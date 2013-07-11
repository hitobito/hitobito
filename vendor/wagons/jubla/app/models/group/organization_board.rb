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

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Treasurer, Member, GroupAdmin, Alumnus, External, DispatchAddress
  
end
