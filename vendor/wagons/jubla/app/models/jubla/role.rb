module Jubla::Role
  extend ActiveSupport::Concern
  
  included do
    class_attribute :alumnus
    self.alumnus = false
    
    Alumnus.alumnus = true

    after_destroy :create_alumnus_role
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
  
  # Versandadresse. Intended to be used with mailing lists
  class DispatchAddress < ::Role
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

  private

  def create_alumnus_role
    if !self.class.external? && old_enough_to_archive? && last_role_for_person_in_group?
      role = Jubla::Role::Alumnus.new
      role.person = self.person
      role.group = self.group
      role.label = self.class.label
      role.save
    end
  end

  def last_role_for_person_in_group?
     group.roles.where(person_id: person_id).empty?
  end
  
end
