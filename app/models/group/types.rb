module Group::Types
  extend ActiveSupport::Concern
  
  included do
    class_attribute :layer, :role_types, :possible_children, :default_children
    
    # Whether this group type builds a layer or is a regular group. Layers influence some permissions.
    self.layer = false
    # List of the role types that are available for this group type.
    self.role_types = []
    # Child group types that may be created for this group type.
    self.possible_children = []
    # Child groups that are automatically created with a group of this type.
    self.default_children = []
  end
  
  module ClassMethods
    def children(*group_types)
      self.possible_children = group_types + self.possible_children
    end
    
    def roles(*types)
      self.role_types = types + self.role_types
    end
    
    def all_types
      @@all_types ||= collect_types([], root_types)
    end
    
    def root_types(*types)
      @@root_types ||= []
      if types.present?
        reset_types!
        @@root_types += types
      else
        @@root_types.clone
      end
    end
    
    def reset_types!
      @@root_types = []
      @@all_types = nil
      Role.reset_types!
    end
    
    private
    
    def collect_types(all, types)
      types.each do |type|
        unless all.include?(type)
          all << type
          collect_types(all, type.possible_children)
        end
      end
      all
    end
    
  end
end