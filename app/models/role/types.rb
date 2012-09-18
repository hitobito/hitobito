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
      # do a double reverse to get roles appearing more than once at the end (uniq keeps the first..)
      @@all_types ||= Group.all_types.collect(&:role_types).flatten.reverse.uniq.reverse
    end
    
    def visible_types
      all_types.select(&:visible_from_above)
    end
    
    def types_with_permission(*permissions)
      all_types.select {|r| (permissions - r.permissions).blank? }
    end
    
    def external_types
      all_types.select(&:external)
    end
    
    def reset_types!
      @@all_types = nil
    end
  end
end
