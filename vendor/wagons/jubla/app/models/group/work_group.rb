# Abstract Work Group
class Group::WorkGroup < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:group_read]
  end

end
