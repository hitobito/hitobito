# Ebene Kanton
class Group::State < Group
  
  self.layer = true
  self.default_children = [Group::StateAgency, Group::StateBoard]
  self.contact_group_type = Group::StateAgency
  self.event_types = [Event, Event::Course]
  
  roles Jubla::Role::Coach
  
  children Group::StateAgency,
           Group::StateBoard,
           Group::ProfessionalGroup,
           Group::WorkGroup,
           Group::Region,
           Group::Flock
           
           
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage]), :as => :superior
  
end