# Ebene Kanton
class Group::State < Group
  
  self.layer = true
  self.default_children = [Group::StateAgency, Group::StateBoard]
  self.contact_group_type = Group::StateAgency
  self.event_types = [Event, Event::Course]
  
    
  class Coach < Jubla::Role::Coach
  end
  
  class Alumnus < Jubla::Role::Alumnus
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class External < Jubla::Role::External
  end

  roles Coach, Alumnus, DispatchAddress, GroupAdmin, External
  
  children Group::StateAgency,
           Group::StateBoard,
           Group::StateProfessionalGroup,
           Group::StateWorkGroup,
           Group::Region,
           Group::Flock
           
           
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage]), :as => :superior
  
  def census_total(year)
    MemberCount.total_by_states(year).where(state_id: id).first
  end
  
  def census_groups(year)
    MemberCount.total_by_flocks(year, self)
  end
  
  def census_details(year)
    MemberCount.details_for_state(year, self)
  end
  
end
