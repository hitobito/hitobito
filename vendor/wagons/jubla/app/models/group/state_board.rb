# Kantonsvorstand
class Group::StateBoard < Group

  class Leader < Jubla::Role::Leader
    self.permissions = [:group_full, :layer_read, :contact_data]
  end

  class Member < Jubla::Role::Member
    self.permissions = [:group_read, :contact_data]
  end

  class President < Member
    attr_accessible :employment_percent, :honorary
  end

  # Stellenbegleitung
  class Supervisor < ::Role
    self.permissions = [:layer_read]
  end

  roles Leader, Member, Supervisor, President

end
