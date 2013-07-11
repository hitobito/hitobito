# Bundesleitung
class Group::FederalBoard < Group

  class Member < Jubla::Role::Member
    self.permissions = [:admin, :layer_full, :contact_data, :qualify]

    attr_accessible :employment_percent
  end

  class President < Member
    attr_accessible :honorary
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Member, President, GroupAdmin, Alumnus, External, DispatchAddress

end
