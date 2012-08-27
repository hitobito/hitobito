# Ebene Kanton
class Group::State < Group
  
  self.layer = true
  self.default_children = [Group::StateAgency, Group::StateBoard]
  
  roles Jubla::Role::Coach
  
  children Group::StateAgency,
           Group::StateBoard,
           Group::ProfessionalGroup,
           Group::WorkGroup,
           Group::Region,
           Group::Flock
           
  attr_accessible :jubla_insurance, :jubla_full_coverage, :as => :superior
  
end