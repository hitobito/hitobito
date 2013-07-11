# Ebene Region
class Group::Region < Group
  
  self.layer = true
  self.default_children = [Group::RegionalBoard]
  
  class Coach < Jubla::Role::Coach
  end
  
  class GroupAdmin < Jubla::Role::GroupAdmin
  end

  class Alumnus < Jubla::Role::Alumnus
  end

  class External < Jubla::Role::External
  end

  class DispatchAddress < Jubla::Role::DispatchAddress
  end

  roles Coach, GroupAdmin, Alumnus, External, DispatchAddress
  
  children Group::RegionalBoard,
           Group::RegionalProfessionalGroup,
           Group::RegionalWorkGroup,
           Group::Flock
           
  attr_accessible *(accessible_attributes.to_a + [:jubla_insurance, :jubla_full_coverage]), :as => :superior

end
