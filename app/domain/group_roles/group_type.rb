module GroupRoles
  class GroupType < Struct.new(:name, :children, :layer, :default_children, :role_types)
    
    @config = ConfigLoader.new
  
    alias layer? layer
    
    def initialize(name, layer = false)
      super(name, [], layer, [], {})
    end
    
    def to_s
      name
    end
    
    def role_type(role_type)
      role_types[role_type.to_s]
    end
    
    
    class << self
            
      # Get a group type with the given name.
      def type(group_type)
        @config.group_types[group_type.to_s]
      end
      
      # Get the role_type of the given group_type-role_type names
      # Name is separated by a dash ('-')
      def role_type(group_role_type)
        g, r = group_role_type.split('-')
        group_type = type(g)
        group_type.role_type(r) if group_type
      end
    
    end
  end
end