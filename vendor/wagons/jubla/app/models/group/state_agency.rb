# Arbeitsstelle AST
class Group::StateAgency < Group
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data, :login]
  end
  
  roles Leader
  
end