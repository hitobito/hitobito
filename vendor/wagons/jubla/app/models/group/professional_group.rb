# Fachgruppe
class Group::ProfessionalGroup < Group


  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :contact_data, :login]
  end
  
  class Member < ::Role
    self.permissions = [:contact_data, :login]
  end
  
  roles Leader, Member
  
end