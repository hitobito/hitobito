module Event::Camp::Role
  class Coach < ::Event::Role

    self.permissions = [:contact_data]
    self.restricted = true
    self.affiliate = true

  end
end
