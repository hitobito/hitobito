class Group::BottomGroup < Group

  children Group::BottomGroup

  class Leader < ::Role
    self.permissions = [:group_full, :login]
  end
  
  class Member < ::Role
    self.visible_from_above = false
  end
  
  roles Leader, Member
  
end