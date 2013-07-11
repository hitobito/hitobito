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

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Member, President, GroupAdmin, Alumnus, External, DispatchAddress

end
