class Group::GlobalGroup < Group

  class Leader < ::Role
    self.permissions = [:group_full]
  end
  
  class Member < ::Role
    self.permissions = [:group_read]
  end
  
  roles Leader, Member
  
end