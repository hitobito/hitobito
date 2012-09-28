# Ebene Schar
class Group::Flock < Group
  
  self.layer = true
  
  children Group::ChildGroup
  
  AVAILABLE_KINDS = %w(Jungwacht Blauring Jubla)
  
  attr_accessible :bank_account, :parish, :kind, :unsexed, :clairongarde, :founding_year
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage, :coach_id, :advisor_id]), as: :superior


  belongs_to :advisor, class_name: "Person"
  belongs_to :coach, class_name: "Person"


  validates :kind, inclusion: AVAILABLE_KINDS


  def available_coaches 
    Person.in_layer(*layer_groups).where(roles: { type: Jubla::Role::Coach.sti_name })
  end

  def available_advisors
    Person.in_layer(*layer_groups).
      where(groups: { type: [Group::StateBoard, Group::RegionalBoard].collect(&:sti_name) }).
      where('roles.type NOT IN (?)', Role.affiliate_types.collect(&:sti_name))
  end
  
  def to_s
    if attributes.include?(:kind)
      [kind, super].compact.join(" ")
    else
      # if kind is not selected from the database, we end up here
      super
    end 
  end


  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data, :login]
  end
  
  class CampLeader < ::Role
    self.permissions = [:layer_full, :contact_data, :login]
  end
  
  # Präses
  class President < ::Role
    self.permissions = [:layer_read, :contact_data, :login]
    
    attr_accessible :employment_percent, :honorary
  end
  
  # Leiter
  class Guide < ::Role
    self.permissions = [:layer_read, :login]
  end
  
  class Treasurer < Jubla::Role::Treasurer
    self.permissions = [:layer_read, :contact_data, :login]
  end
  
  roles Leader, CampLeader, President, Guide, Treasurer
  
end
