# Ebene Region
class Group::Region < Group
  
  self.layer = true
  self.default_children = [Group::RegionalBoard]
  
  class Coach < Jubla::Role::Coach
  end
  
  roles Coach
  
  children Group::RegionalBoard, 
           Group::RegionalProfessionalGroup, 
           Group::RegionalWorkGroup, 
           Group::Flock
           
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage]), :as => :superior

end