# Regionalleitung
class Group::RegionalBoard < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :layer_read, :contact_data]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:layer_read, :contact_data]
  end

  class President < Member
  end
  
  roles Leader, Member, President
  
end
