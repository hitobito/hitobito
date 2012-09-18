# Kantonsvorstand
class Group::StateBoard < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :layer_read, :contact_data, :login]
  end
  
  class Member < Jubla::Role::Member
    self.permissions = [:contact_data, :login]
  end
  
  # Stellenbegleitung
  class Supervisor < ::Role
    self.permissions = [:layer_read, :login]
  end
  
  roles Leader, Member, Supervisor
  
end