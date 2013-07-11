# Einfache Gruppe, kann überall angehängt werden.
class Group::SimpleGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:group_read]
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Member, GroupAdmin, Alumnus, External, DispatchAddress
end
