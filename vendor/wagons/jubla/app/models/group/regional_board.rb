# Regionalleitung
class Group::RegionalBoard < Group

  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data]
  end

  class Member < Jubla::Role::Member
    self.permissions = [:layer_read, :contact_data]
  end

  class President < Member
    attr_accessible :employment_percent, :honorary
  end

  roles Leader, Member, President

end
