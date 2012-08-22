module GroupRoles
  class ConfigLoader
    
    CONFIG_FILE = Rails.root.join('config', 'group_types.yml')
    
    def group_types
      load unless @loaded
      @group_types
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
      @group_types.each do |group_name, group_type|
        attrs = config['group_types'][group_name]
        roles = attrs['roles'] || {}
        roles = config['common_roles'].merge(roles) if config['common_roles'].present?
        roles.each do |role_name, attrs|
          add_role_type(config, group_type, role_name, attrs)
        end
      end
    end
    
    def add_role_type(config, group_type, name, attrs)
      assert_exists(config, 'role_types', name)
      
      group_type.role_types[name] = role = RoleType.new(name)
      return if attrs.blank?
      
      role.permissions = type_list(attrs['permissions']) do |p|
        assert_exists(config, 'permissions', p) 
        p.to_sym
      end
      role.visible_from_above = attrs['visible_from_above'] != false
      role.external = attrs['external'] || false
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