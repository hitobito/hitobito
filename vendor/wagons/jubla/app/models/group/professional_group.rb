# Fachgruppe
class Group::ProfessionalGroup < Group


  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data, :login]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:contact_data, :login]
  end
  
  roles Leader, Member
  
end