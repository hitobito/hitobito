module GroupRoles
  class RoleType < Struct.new(:name, :permissions, :visible_from_above, :external)
    
    alias visible_from_above? visible_from_above
    alias external? external
    
    def initialize(name)
      super(name, [], true, false)
    end
    
    def to_s
      name
    end
    
  end
end