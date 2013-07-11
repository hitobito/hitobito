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

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, Member, Supervisor, President, GroupAdmin, Alumnus, External, DispatchAddress

end
