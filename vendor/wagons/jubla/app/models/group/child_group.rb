# Kindergruppe
class Group::ChildGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
  end
    
  class Child < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Child, GroupAdmin, Alumnus, External, DispatchAddress
  
end
