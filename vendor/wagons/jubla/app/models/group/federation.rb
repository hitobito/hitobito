# Ebene Bund
class Group::Federation < Group
  
  self.layer = true
  self.default_children = [Group::FederalBoard, Group::OrganizationBoard]
  
  children Group::FederalBoard,
           Group::OrganizationBoard,
           Group::State,
           Group::ProfessionalGroup,
           Group::WorkGroup
  
end