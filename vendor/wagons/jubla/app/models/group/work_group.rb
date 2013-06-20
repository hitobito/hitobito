# Abstract Work Group
class Group::WorkGroup < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:group_read]
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Alumnus, DispatchAddress, GroupAdmin, External
  
end
