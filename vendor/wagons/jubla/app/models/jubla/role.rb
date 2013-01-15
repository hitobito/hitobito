module Jubla::Role
  extend ActiveSupport::Concern
  
  included do
    class_attribute :alumnus
    self.alumnus = false
    
    Alumnus.alumnus = true
  end
  
  
  module ClassMethods
    
    # An role external to a group, i.e. affiliate but not restricted
    def external?
      affiliate && !restricted && !alumnus
    end
    
  end
  
  
  
  # Common roles not attached to a specific group
  
  # Adressverwaltung
  class GroupAdmin < ::Role
    self.permissions = [:group_full]
  end
  
  # Extern
  class External < ::Role
    self.permissions = []
    self.visible_from_above = false
    self.affiliate = true
  end
  
  # Ehemalige
  class Alumnus < ::Role
    self.permissions = [:group_read]
    self.affiliate = true
  end
  
  # Common superclass for all J+S Coach roles
  class Coach < ::Role
    self.permissions = [:contact_data, :group_read]
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