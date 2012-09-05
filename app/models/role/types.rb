module Role::Types
  extend ActiveSupport::Concern
  
  included do
    class_attribute :permissions, :visible_from_above, :external
    self.permissions = []
    self.visible_from_above = true
    self.external = false
  end
  
  module ClassMethods
    def all_types
      @@all_types ||= Group.all_types.collect(&:role_types).flatten.uniq
    end
    
    def visible_types
      all_types.select(&:visible_from_above)
    end
    
    def types_with_permission(*permissions)
      all_types.select {|r| (permissions - r.permissions).blank? }
    end
    
    def reset_types!
      @@all_types = nil
    end
  end
end
