module Event::Course::Role
  class Advisor < ::Event::Role

    self.permissions = [:contact_data]
    self.restricted = true
    self.affiliate = true

  end
end
