# Ebene Bund
class Group::Federation < Group
  
  self.layer = true
  self.default_children = [Group::FederalBoard, Group::OrganizationBoard]
  
  children Group::FederalBoard,
           Group::OrganizationBoard,
           Group::ProfessionalGroup,
           Group::WorkGroup,
           Group::State
  
end