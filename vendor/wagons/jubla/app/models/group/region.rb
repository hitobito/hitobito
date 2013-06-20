# Ebene Region
class Group::Region < Group
  
  self.layer = true
  self.default_children = [Group::RegionalBoard]
  
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
  
  children Group::RegionalBoard,
           Group::RegionalProfessionalGroup,
           Group::RegionalWorkGroup,
           Group::Flock
           
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage]), :as => :superior

end
