# Arbeitsstelle AST
class Group::StateAgency < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data, :qualify]
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Alumnus, DispatchAddress, GroupAdmin, External
  
end
