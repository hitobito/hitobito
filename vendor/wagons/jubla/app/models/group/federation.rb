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
  
end