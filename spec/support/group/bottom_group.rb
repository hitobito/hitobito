class Group::BottomGroup < Group

  children Group::BottomGroup

  class Leader < ::Role
    self.permissions = [:group_full]
  end
  
  class Member < ::Role
    self.permissions = [:group_read]
    self.visible_from_above = false
  end
  
  roles Leader, Member
  
end