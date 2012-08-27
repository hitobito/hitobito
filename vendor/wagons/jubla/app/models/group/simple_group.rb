# Einfache Gruppe, kann überall angehängt werden.
class Group::SimpleGroup < Group
  
  
  class Leader < ::Role
    self.permissions = [:group_full]
  end
  
  class Member < ::Role
  end
  
  roles Leader, Member
end