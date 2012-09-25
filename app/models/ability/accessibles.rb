# This class is only used for fetching lists based on a group association.
class Ability::Accessibles
  include Ability::Common
  
  def initialize(user, group)
    raise "Group cannot be nil" if group.nil?
    super(user)

    ### PEOPLE  
      
    # list people belonging to to the given group
    if user_groups.include?(group.id)
      # user has any role in this group
      can :index, Person, group.people.only_public_data do |p| true end
    elsif layers_read.present?
      if layers_read.include?(group.layer_group_id)
        # user has layer read of the same layer as the group
        can :index, Person, group.people.only_public_data do |p| true end
      elsif contains_any?(layers_read, collect_ids(group.layer_groups))
        # user has layer read in a above layer of the group
        can :index, Person, group.people.only_public_data.visible_from_above(group) do |p| true end
      end
    elsif user.contact_data_visible?
      can :index, Person, group.people.only_public_data.contact_data_visible do |p| true end
    end

    if layers_read.present?
      if layers_read.include?(group.layer_group_id)
        # user has layer read of the same layer as the group
        can :layer_search, Person, Person.only_public_data.in_layer(group.layer_group) do |p| true end
        can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group) do |p| true end
      elsif contains_any?(layers_read, collect_ids(group.layer_groups))
        # user has layer read in a above layer of the group
        can :layer_search, Person, Person.only_public_data.visible_from_above.in_layer(group.layer_group) do |p| true end
        can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group) do |p| true end
      end
    elsif user.contact_data_visible?
      can :layer_search, Person, Person.only_public_data.contact_data_visible.in_layer(group.layer_group) do |p| true end
      can :deep_search, Person, Person.only_public_data.contact_data_visible.in_or_below(group.layer_group) do |p| true end
    elsif user_groups.include?(group.id) # this is last here as it has the least search abilities
      can :layer_search, Person, Person.only_public_data.in_layer(group.layer_group).where('roles.group_id' => user.groups) do |p| true end
      can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below(group.layer_group).where('roles.group_id' => user.groups) do |p| true end
    end
    
  end

end
