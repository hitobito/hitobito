# Ebene Bund
class Group::Federation < Group
  
  self.layer = true
  self.default_children = [Group::FederalBoard, Group::OrganizationBoard]
  self.contact_group_type = Group::FederalBoard
  self.event_types = [Event, Event::Course]
  
  children Group::FederalBoard,
           Group::OrganizationBoard,
           Group::ProfessionalGroup,
           Group::WorkGroup,
           Group::State
  
  def census_total(year)
    MemberCount.total_for_federation(year)
  end

  def census_groups(year)
    MemberCount.total_by_states(year)
  end
  
  def census_details(year)
    MemberCount.details_for_federation(year, self)
  end 
end