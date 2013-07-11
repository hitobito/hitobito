# Ebene Schar
class Group::Flock < Group

  include RestrictedRole

  self.layer = true
  self.event_types = [Event, Event::Camp]

  children Group::ChildGroup

  AVAILABLE_KINDS = %w(Jungwacht Blauring Jubla)

  attr_accessible :bank_account, :parish, :kind, :unsexed, :clairongarde, :founding_year
  attr_accessible *(accessible_attributes.to_a +
                    [:jubla_insurance, :jubla_full_coverage, :coach_id, :advisor_id]),
                  as: :superior


  has_many :member_counts


  validates :kind, inclusion: AVAILABLE_KINDS, allow_blank: true


  def available_coaches
    coach_role_types = [Group::State::Coach, Group::Region::Coach].collect(&:sti_name)
    Person.in_layer(*layer_hierarchy).
           where(roles: { type: coach_role_types })
  end

  def available_advisors
    advisor_group_types = [Group::StateBoard, Group::RegionalBoard].collect(&:sti_name)
    Person.in_layer(*layer_hierarchy).
           where(groups: { type: advisor_group_types }).
           where('roles.type NOT IN (?)', Role.affiliate_types.collect(&:sti_name))
  end

  def to_s
    if attributes.include?('kind')
      [kind, super].compact.join(" ")
    else
      # if kind is not selected from the database, we end up here
      super
    end
  end

  def state
    ancestors.where(type: Group::State.sti_name).first
  end

  def census_groups(year)
    []
  end

  def census_total(year)
    MemberCount.total_for_flock(year, self)
  end

  def census_details(year)
    MemberCount.details_for_flock(year, self)
  end

  def population_approveable?
    current_census = Census.current
    current_census && !MemberCounter.new(current_census.year, self).exists?
  end

  class Leader < Jubla::Role::Leader
    self.permissions = [:layer_full, :contact_data, :approve_applications]
  end

  class CampLeader < ::Role
    self.permissions = [:layer_full, :contact_data]
  end

  # Präses
  class President < ::Role
    self.permissions = [:layer_read, :contact_data]

    attr_accessible :employment_percent, :honorary
  end

  # Leiter
  class Guide < ::Role
    self.permissions = [:layer_read]
  end

  # Kassier
  class Treasurer < Jubla::Role::Treasurer
    self.permissions = [:layer_read, :contact_data]
  end

  # Coach
  class Coach < ::Role
    self.permissions = [:layer_read]
    self.affiliate   = true
    self.restricted  = true
    self.visible_from_above = false
  end

  # Betreuer
  class Advisor < ::Role
    self.permissions = [:layer_read]
    self.affiliate   = true
    self.restricted  = true
    self.visible_from_above = false
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Leader, CampLeader, President, Treasurer, Guide, GroupAdmin, Alumnus, External, DispatchAddress
  restricted_role :coach, Coach
  restricted_role :advisor, Advisor

end
