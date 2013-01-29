module Jubla::PeopleFilterHelper
  
  def main_people_filter_items_with_alumni
    items = main_people_filter_items_without_alumni
    
    if can?(:index_full_people, @group) || can?(:index_local_people, @group) 
      items << people_pill_item('Ehemalige', 
                                group_people_path(@group, 
                                                  role_types: [Role::Alumnus.sti_name], 
                                                  name: 'Ehemalige'))
    end
    
    items
  end
  
end