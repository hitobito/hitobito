# Fachgruppe
class Group::RegionalProfessionalGroup < Group::ProfessionalGroup

  class Leader < Group::ProfessionalGroup::Leader
  end
  
  class Member < Group::ProfessionalGroup::Member
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
