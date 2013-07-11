# Arbeitsstelle AST
class Group::StateAgency < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data, :qualify]
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, GroupAdmin, Alumnus, External, DispatchAddress
  
end
