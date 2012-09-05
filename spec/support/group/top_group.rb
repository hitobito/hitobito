class Group::TopGroup < Group


  class Leader < ::Role
    self.permissions = [:layer_full, :contact_data, :login]
  end
  
  class Member < ::Role
    self.permissions = [:contact_data, :login]
  end
  
  roles Leader, Member
  
end