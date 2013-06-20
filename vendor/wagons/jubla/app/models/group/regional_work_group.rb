class Group::RegionalWorkGroup < Group::WorkGroup

  class Leader < Group::WorkGroup::Leader
  end
  
  class Member < Group::WorkGroup::Member
  end
  
  class Alumnus < Jubla::Role::Alumnus
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Member, Alumnus, DispatchAddress, GroupAdmin, External
  
end
