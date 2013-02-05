module Jubla::FilterNavigation::People
  
  extend ActiveSupport::Concern
  
  included do
    FilterNavigation::People::PREDEFINED_FILTERS << 'Ehemalige'
    
    alias_method_chain :init_items, :alumni
  end
  
  def init_items_with_alumni
    init_items_without_alumni
    
    if can?(:index_full_people, group) || can?(:index_local_people, group) 
      item('Ehemalige', 
           filter_path(role_types: [Role::Alumnus.sti_name], 
                       name: 'Ehemalige'))
    end
  end
end