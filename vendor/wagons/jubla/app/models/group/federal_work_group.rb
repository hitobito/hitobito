class Group::FederalWorkGroup < Group::WorkGroup

  class Leader < Group::WorkGroup::Leader
  end
  
  class Member < Group::WorkGroup::Member
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Member, GroupAdmin, Alumnus, External, DispatchAddress
  
end
