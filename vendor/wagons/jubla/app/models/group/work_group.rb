class Group::WorkGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data, :login]
  end
  
  class Member < ::Role
    self.permissions = [:login]
  end
  
  roles Leader, Member
  
end