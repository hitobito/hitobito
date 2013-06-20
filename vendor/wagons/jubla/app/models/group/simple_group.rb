# Einfache Gruppe, kann überall angehängt werden.
class Group::SimpleGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
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

  roles Leader, Member, Alumnus, DispatchAddress, GroupAdmin, External
end
