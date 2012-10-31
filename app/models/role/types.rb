module Role::Types
  extend ActiveSupport::Concern
  
  Permissions = [:admin, :layer_full, :layer_read, :group_full, :contact_data, :login, :qualify, :approve_applications] 
  
  
  included do
    class_attribute :permissions, :visible_from_above, :affiliate, :restricted
    # All permission a person with this role has on the corresponding group.
    self.permissions = []
    # Whether a person with this role is visible for somebody with layer_read permission above the current layer.
    self.visible_from_above = true
    # Whether this role is an active member or an affiliate person of the corresponding group.
    self.affiliate = false
    # Whether this kind of role is specially managed or open for general modifications.
    self.restricted = false
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
    
    def affiliate_types
      all_types.select(&:affiliate)
    end
    
    def reset_types!
      @@all_types = nil
    end
  end
end
