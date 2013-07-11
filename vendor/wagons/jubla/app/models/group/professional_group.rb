# Abstract professional group (Fachgruppe)
class Group::ProfessionalGroup < Group
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:contact_data, :group_read]
  end

end
