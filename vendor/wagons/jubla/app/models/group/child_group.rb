# Kindergruppe
class Group::ChildGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :login]
  end
    
  class Child < ::Role
    self.visible_from_above = false
  end
  
  roles Leader, Child
  
end