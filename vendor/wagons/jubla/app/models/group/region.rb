# Ebene Region
class Group::Region < Group
  
  self.layer = true
  self.default_children = [Group::RegionalBoard]
  
  roles Jubla::Role::Coach
  
  children Group::RegionalBoard, 
           Group::ProfessionalGroup, 
           Group::WorkGroup, 
           Group::Flock
           
  attr_accessible :jubla_insurance, :jubla_full_coverage, :as => :superior

end