module PeopleFilterHelper
  
  def people_filter_links
    links = main_people_filter_links
    if @group.layer?
      add_custom_people_filter_links(links)
      add_define_custom_people_filter_link(links)
    end
    links
  end

  def people_filter_name
    params[:name] || (params[:role_types] ? 'Eigener Filter' : 'Mitglieder')
  end
  
  private
  
  def main_people_filter_links
    links = []
    links << link_to('Mitglieder', group_people_path(@group))
    if can?(:index_local_people, @group)
      links << link_to('Externe', 
                       group_people_path(@group, 
                                         role_types: Role.external_types.collect(&:sti_name), 
                                         name: 'Externe'))
    end
    links
  end
  
  def add_custom_people_filter_links(links)
    filters = PeopleFilter.for_group(@group)
    if filters.present?
      links << nil
      filters.each { |filter| links << people_filter_link(filter) }
    end
  end
  
  def add_define_custom_people_filter_link(links)
    if can?(:new, @group.people_filters.new)
      links << nil
      links << link_to('Neuer Filter...', 
                       new_group_people_filter_path(@group.id, people_filter: params.slice(:kind, :role_types)))
    end
  end
  
  def people_filter_link(filter)
     link = group_people_path(@group, kind: filter.kind, role_types: filter.role_types, name: filter.name)
     html = link_to(filter.name, link)

     if can?(:destroy, filter)
       { html => [link_action_destroy(group_people_filter_path(@group, filter))] }
     else
       html
     end
  end
  
end