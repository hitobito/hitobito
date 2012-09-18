# Einfache Gruppe, kann überall angehängt werden.
class Group::SimpleGroup < Group
  
  
  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full]
  end
  
  class Member < Jubla::Role::Member
  end
  
  roles Leader, Member
end