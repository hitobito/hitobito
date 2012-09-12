# An ability that takes the current group as an additional argument.
# This class is only used for generating lists of group associations.
class Ability::WithGroup < Ability::Base
  
  def initialize(user, group)
    super(user)
      
    ### GROUPS
    
    can :read, Group
    
    if modify_permissions?
      if can_create_or_destroy_group?(group)
        can [:create, :destroy], Group do |g|
          group == g
        end 
      end
      
      can :update, Group do |g|
        group == g &&
        can_update_group?(g)
      end
    end
    
    ### PEOPLE  
      
    # list people belonging to to the given group
    if user.groups.include?(group)
      # user has any role in this group
      can :index, Person, group.people.only_public_data do |p| true end
      can :external, Person
    elsif layers_read.present?
      if layers_read.include?(group.layer_group)
        # user has layer read of the same layer as the group
        can :index, Person, group.people.only_public_data do |p| true end
        can :external, Person
      elsif contains_any?(layers_read, group.layer_groups)
        # user has layer read in a above layer of the group
        can :index, Person, group.people.only_public_data.visible_from_above(group) do |p| true end
      end
    elsif user.contact_data_visible?
      can :index, Person, group.people.only_public_data.contact_data_visible do |p| true end
    end

    if layers_read.present?
      if layers_read.include?(group.layer_group)
        # user has layer read of the same layer as the group
        can :layer_search, Person, Person.only_public_data.in_layer(group.layer_group) do |p| true end
        can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group) do |p| true end
      elsif contains_any?(layers_read, group.layer_groups)
        # user has layer read in a above layer of the group
        can :layer_search, Person, Person.only_public_data.visible_from_above.in_layer(group.layer_group) do |p| true end
        can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group) do |p| true end
      end
    elsif user.contact_data_visible?
      can :layer_search, Person, Person.only_public_data.contact_data_visible.in_layer(group.layer_group) do |p| true end
      can :deep_search, Person, Person.only_public_data.contact_data_visible.in_or_below(group.layer_group) do |p| true end
    elsif user.groups.include?(group) # this is last here as it has the least search abilities
      can :layer_search, Person, Person.only_public_data.in_layer(group.layer_group).where('roles.group_id' => user.groups) do |p| true end
      can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group).where('roles.group_id' => user.groups) do |p| true end
    end
    
  end
  
  private
    
  def can_update_group?(group)
    # user has group_full for this group
    groups_group_full.include?(group) ||
    can_create_or_destroy_group?(group)
  end
    
  def can_create_or_destroy_group?(group)
    layers_full.present? && 
     # user has layer_full, group in same layer
     contains_any?(layers_full, group.layer_groups)
  end
end