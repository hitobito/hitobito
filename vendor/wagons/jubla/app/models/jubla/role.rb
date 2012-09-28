module Jubla::Role
  extend ActiveSupport::Concern
  
  # Common roles not attached to a specific group
  
  class GroupAdmin < ::Role
    self.permissions = [:group_full, :login]
  end
  
  class External < ::Role
    self.permissions = []
    self.visible_from_above = false
    self.affiliate = true
  end
  
  # J+S Coach
  class Coach < ::Role
    self.permissions = [:contact_data, :login]
  end
  
  # Common superclass for all leader roles
  # Primarly used for common naming
  class Leader < ::Role
    
  end
  
  # Common superclass for all member roles
  # Primarly used for common naming
  class Member < ::Role
    
  end
  
  # Common superclass for all traesurer roles
  class Treasurer < ::Role
    
  end
  
  
end