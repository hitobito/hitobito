class GroupType < Struct.new(:name, :children, :layer, :default_children, :role_types)
  
  CONFIG_FILE = Rails.root.join('config', 'group_types.yml')
  
  @loaded = false
  
  def initialize(name, layer = false)
    super(name, [], layer, [], {})
  end
  
  def to_s
    name
  end
  
  def permissions(role_type)
    role_types[role_type.to_s]
  end
  
  def layer?
    layer
  end
  
  class << self
    
    # Get a group type with the given name.
    def type(group_type)
      load unless @loaded
      @group_types[group_type.to_s]
    end
    
    # Get the permission of the given group_type-role_type names
    # Name is separated by a dash ('-')
    def permissions(group_role_type)
      g, r = group_role_type.split('-')
      group_type = type(g)
      group_type.permissions(r) if group_type
    end
    
    def load
      config = YAML::load( File.open( CONFIG_FILE ) )
      load_group_types(config)
      assign_children(config)
      assign_role_types(config)
      @loaded = true
    end
    
    private
    
    def load_group_types(config)
      @group_types = {}
      config['group_types'].each do |name, attrs|
        @group_types[name] = GroupType.new(name, attrs['layer'] || false)
      end
    end
    
    def assign_children(config)
      @group_types.each do |name, type|
        attrs = config['group_types'][name]
        type.children = group_type_list(attrs['children'])
        type.children += config['common_children'].collect{|t| @group_types[t] } if config['common_children']
        type.default_children = group_type_list(attrs['default_children'])
      end
    end
    
    def assign_role_types(config)
      @group_types.each do |name, group_type|
        attrs = config['group_types'][name]
        roles = attrs['roles'] || {}
        roles = config['common_roles'].merge(roles) if config['common_roles']
        roles.each do |role, permission_string|
          add_role_type(config, group_type, role, permission_string)
        end
      end
    end
    
    def add_role_type(config, group_type, role, permission_string)
      assert_exists(config, 'role_types', role)
      permissions = type_list(permission_string) do |p|
        assert_exists(config, 'permissions', p) 
        p.to_sym
      end
      group_type.role_types[role] = permissions
    end
    
    def group_type_list(string)
      type_list(string) { |t| @group_types[t] }
    end
    
    def type_list(string, &block)
      return [] if string.blank?
      string.split(',').collect(&:strip).collect(&block)
    end
    
    def assert_exists(config, key, value)
      raise "'#{value}' is not a defined #{key.singularize}" unless config[key].include?(value)
    end
    
  end
end
