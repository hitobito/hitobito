# Bundesleitung
class Group::FederalBoard < Group

  class Member < Jubla::Role::Member
    self.permissions = [:admin, :layer_full, :contact_data, :qualify]

    attr_accessible :employment_percent
  end

  class President < Member
    attr_accessible :honorary
  end

  roles Member, President

end
