module PeopleFilterHelper

  PREDEFINED_FILTERS = %w(Mitglieder Externe)

  def people_filter_navigation
    pill_navigation(main_people_filter_items, custom_people_filter_links, *custom_people_filter_label)
  end
  
  private
  
  def main_people_filter_items
    items = []
    items << people_pill_item('Mitglieder', group_people_path(@group))
    if can?(:index_local_people, @group)
      items << people_pill_item('Externe', 
                                 group_people_path(@group, 
                                                   role_types: Role.external_types.collect(&:sti_name), 
                                                   name: 'Externe'))
    end
    items
  end
  
  def custom_people_filter_links
    links = []
    if @group.layer?
      add_custom_people_filter_links(links)
      add_define_custom_people_filter_link(links)
    end
    links
  end
  
  def custom_people_filter_label
    if params[:name].present?
      if PREDEFINED_FILTERS.include?(params[:name])
        ['Weitere Ansichten', false]
      else
        [params[:name], true]
      end
    elsif params[:role_types].present?
      ['Eigener Filter', true]
    else
      ['Weitere Ansichten', false]
    end
  end
  
  def people_pill_item(label, url)
    pill_item(link_to(label, url), active_people_filter_label == label)
  end
  
  def active_people_filter_label
    params[:name].presence || params[:role_types].present? || PREDEFINED_FILTERS.first
  end
  
  def add_custom_people_filter_links(links)
    filters = PeopleFilter.for_group(@group)
    filters.each { |filter| links << people_filter_link(filter) }
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