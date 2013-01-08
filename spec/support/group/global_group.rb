class Group::GlobalGroup < Group

  class Leader < ::Role
    self.permissions = [:group_full, :login]
  end
  
  class Member < ::Role
  end
  
  roles Leader, Member
  
end