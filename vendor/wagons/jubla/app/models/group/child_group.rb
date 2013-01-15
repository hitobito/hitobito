# Kindergruppe
class Group::ChildGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
  end
    
  class Child < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end
  
  roles Leader, Child
  
end