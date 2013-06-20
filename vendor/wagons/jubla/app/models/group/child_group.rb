# Kindergruppe
class Group::ChildGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
  end
    
  class Child < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end
  
  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  class Alumnus < Jubla::Role::Alumnus
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Child, DispatchAddress, Alumnus, GroupAdmin, External
  
end
