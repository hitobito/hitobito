module FilterNavigation
  class People < Base
    
    PREDEFINED_FILTERS = %w(Mitglieder Externe)
    
    attr_reader :group, :name, :role_types, :kind
    
    delegate :can?, to: :template
    
    def initialize(template, group, name, role_types, kind)
      super(template)
      @group = group
      @name = name
      @role_types = role_types
      @kind = kind
      init_labels
      init_items
      init_dropdown_links
    end
    
    private
    
    def init_labels
      if name.present?
        if PREDEFINED_FILTERS.include?(name)
          @active_label = name
        else
          @dropdown_label = name
          @dropdown_active = true
        end
      elsif role_types.present?
        @dropdown_label = 'Eigener Filter'
        @dropdown_active = true
      else
        @active_label = PREDEFINED_FILTERS.first
      end
    end
    
    def init_items
      item('Mitglieder', filter_path)
      if can?(:index_local_people, group)
        item('Externe', 
             filter_path(role_types: Role.external_types.collect(&:sti_name), 
                         name: 'Externe'))
      end
    end
    
    def init_dropdown_links
      if group.layer?
        add_custom_people_filter_links
        add_define_custom_people_filter_link
      end
    end
     
    def add_custom_people_filter_links
      filters = PeopleFilter.for_group(group)
      filters.each { |filter| dropdown_link(people_filter_link(filter)) }
    end
    
    def add_define_custom_people_filter_link
      if can?(:new, group.people_filters.new)
        link = template.new_group_people_filter_path(group.id, people_filter: {kind: kind, role_types: role_types})
        dropdown_link(nil) if dropdown_links.present?
        dropdown_link(link_to('Neuer Filter...', link))
      end
    end
    
    def people_filter_link(filter)
       link = filter_path(kind: filter.kind, role_types: filter.role_types, name: filter.name)
       html = link_to(filter.name, link)
  
       if can?(:destroy, filter)
         { html => [template.link_action_destroy(template.group_people_filter_path(group, filter))] }
       else
         html
       end
    end
    
    def filter_path(options = {})
      template.group_people_path(group, options)
    end
    
  end
end