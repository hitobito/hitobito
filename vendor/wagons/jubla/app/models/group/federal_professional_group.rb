# Fachgruppe
class Group::FederalProfessionalGroup < Group::ProfessionalGroup

  class Leader < Group::ProfessionalGroup::Leader
  end
  
  class Member < Group::ProfessionalGroup::Member
  end
  
  class Alumnus < Jubla::Role::Alumnus
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Leader, Member, Alumnus, GroupAdmin, External
  
end
