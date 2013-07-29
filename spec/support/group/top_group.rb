class Group::TopGroup < Group

  self.event_types = [Event, Event::Course]

  class Leader < ::Role
    self.permissions = [:admin, :layer_full, :contact_data]
  end

  class Secretary < ::Role
    self.permissions = [:layer_read, :contact_data, :group_full]
  end

  class Member < ::Role
    self.permissions = [:contact_data, :group_read]
  end

  roles Leader, Secretary, Member

end
