class Ability::WithGroup < Ability::Base
  
  def initialize(user, group)
    super(user)
      
      # list people belonging to to the given group
    if user.groups.include?(group)
      # user has any role in this group
      can :index, Person, group.people.only_public_data
    elsif layers_read.present?
      if layers_read.include?(group.layer_group)
        # user has layer read of the same layer as the group
        can :index, Person, group.people.only_public_data
      elsif contains_any?(layers_read, group.layer_groups)
        # user has layer read in a above layer of the group
        can :index, Person, group.people.only_public_data.visible_from_above(group)
      end
    elsif user.contact_data_visible?
      can :index, Person, group.people.only_public_data.contact_data_visible
    end
    
    # search people in the layer the given group
    if layers_read.present?
      if layers_read.include?(group.layer_group)
        # user has layer_read in the groups layer. 
        can :layer_search, Person, Person.only_public_data.in_layer(group.layer_group)
      elsif contains_any?(layers_read, group.layer_groups)
        # user has layer_read in a layer above the group. 
        can :layer_search, Person, Person.only_public_data.visible_from_above.in_layer(group.layer_group)
      end
    elsif user.contact_data_visible?
      can :layer_search, Person, Person.only_public_data.contact_data_visible.in_layer(group.layer_group)
    end
    
    # search people in the layer or below of the given group
    if layers_read.present? && contains_any?(layers_read, group.layer_groups)
      # user has layer_read in a layer above the group. 
      can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group)
    elsif user.contact_data_visible?
      can :deep_search, Person, Person.only_public_data.contact_data_visible.in_or_below(group.layer_group)
    end
  end
end