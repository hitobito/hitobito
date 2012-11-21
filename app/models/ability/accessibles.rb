# This class is only used for fetching lists based on a group association.
class Ability::Accessibles
  include Ability::Common
  
  attr_reader :group
  
  def initialize(user, group)
    raise "Group cannot be nil" if group.nil?
    super(user)
    @group = group

    ### PEOPLE  
      
    # list people belonging to to the given group
    
    # user has any role in this group
    if belonging_to_this_group?
      can :index, Person, 
          group.people.only_public_data do |p| true end
            
    # user has layer read of the same layer as the group
    elsif layer_read_in_same_layer?
      can :index, Person, 
          group.people.only_public_data do |p| true end
        
    # user has layer read in a above layer of the group
    elsif layer_read_in_above_layer?
      can :index, Person, 
          group.people.only_public_data.visible_from_above(group) do |p| true end
        
    elsif user.contact_data_visible?
      can :index, Person, 
          group.people.only_public_data.contact_data_visible do |p| true end
        
    end

    # same conditions again, but different ordering because of user_groups
    
    # user has layer read of the same layer as the group
    if layer_read_in_same_layer?
      can :layer_search, Person, 
          Person.only_public_data.
                 in_layer(group.layer_group) do |p| true end
                   
      can :deep_search, Person, 
          Person.only_public_data.
                 visible_from_above.
                 in_or_below(group.layer_group) do |p| true end
                   
    # user has layer read in a above layer of the group
    elsif layer_read_in_above_layer?
      can :layer_search, Person, 
          Person.only_public_data.
                 visible_from_above.
                 in_layer(group.layer_group) do |p| true end
                   
      can :deep_search, Person, 
          Person.only_public_data.
                 visible_from_above.
                 in_or_below(group.layer_group) do |p| true end
                   
    elsif user.contact_data_visible?
      can :layer_search, Person, 
          Person.only_public_data.
                 contact_data_visible.
                 in_layer(group.layer_group) do |p| true end
                   
      can :deep_search, Person, 
           Person.only_public_data.
                  contact_data_visible.
                  in_or_below(group.layer_group) do |p| true end
    
    # this is last here as it has the least search abilities
    elsif belonging_to_this_group? 
      can :layer_search, Person, 
          Person.only_public_data.
                 in_layer(group.layer_group).
                 where('roles.group_id' => user.groups) do |p| true end
                   
      can :deep_search, Person, 
          Person.only_public_data.
                 in_or_below(group.layer_group).
                 where('roles.group_id' => user.groups) do |p| true end
    end
    
  end
  
  private
  
  def belonging_to_this_group?
    user_groups.include?(group.id)
  end

  def layer_read_in_same_layer?
    layers_read.present? && layers_read.include?(group.layer_group_id)
  end
  
  def layer_read_in_above_layer?
    layers_read.present? && contains_any?(layers_read, collect_ids(group.layer_groups))
  end
end
