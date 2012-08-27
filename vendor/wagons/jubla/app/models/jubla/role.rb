module Jubla::Role
  extend ActiveSupport::Concern
  
  Permissions = [:layer_full, :layer_read, :group_full, :contact_data, :login] 
  
  
  # Common roles not attached to a specific group
  
  class GroupAdmin < ::Role
    self.permissions = [:group_full]
  end
  
  class External < ::Role
    self.permissions = []
    self.visible_from_above = false
    self.external = true
  end
  
  # J+S Coach
  class Coach < ::Role
    
  end
  
  # Common superclass for all leader roles
  class Leader < ::Role
    
  end
  
  # Common superclass for all traesurer roles
  class Treasurer < ::Role
    
  end
  
  
end