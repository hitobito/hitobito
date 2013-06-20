class Group::FederalWorkGroup < Group::WorkGroup

  class Leader < Group::WorkGroup::Leader
  end
  
  class Member < Group::WorkGroup::Member
  end

  class Alumnus < Jubla::Role::Alumnus
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Member, Alumnus, GroupAdmin, External
  
end
