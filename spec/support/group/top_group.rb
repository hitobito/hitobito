class Group::TopGroup < Group

  self.event_types = [Event, Event::Course]

  class Leader < ::Role
    self.permissions = [:admin, :layer_full, :contact_data, :login, :qualify]
  end
  
  class Member < ::Role
    self.permissions = [:contact_data, :login]
  end
  
  roles Leader, Member
  
end
