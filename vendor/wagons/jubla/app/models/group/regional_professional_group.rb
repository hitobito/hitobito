# Fachgruppe
class Group::RegionalProfessionalGroup < Group::ProfessionalGroup

  class Leader < Group::ProfessionalGroup::Leader
  end
  
  class Member < Group::ProfessionalGroup::Member
  end
  
  roles Leader, Member
  
end