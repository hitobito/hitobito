# This class is only used for fetching lists based on a group association.
class Ability::Accessibles
  include Ability::Common
  
  attr_reader :group
  
  def initialize(user, group = nil)
    super(user)
    @group = group

    ### PEOPLE  
      
    
    if @group.nil?
      can :index, Person, accessible_people do |p| true end
        
    else # optimized queries for a given group
      
      # user has any role in this group
      # user has layer read of the same layer as the group
      if belonging_to_this_group? || layer_read_in_same_layer?
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
    end
    
  end
  
  private
  
  def accessible_people
    conditions = [""]
    
    if user.contact_data_visible?
      # people with contact data visible
      or_conditions(conditions, 'people.contact_data_visible = ?', true)
    end
    
    if layers_read.present?
      layer_groups = layers(user.groups_with_permission(:layer_full), 
                            user.groups_with_permission(:layer_read))
      
      # people in same layer
      or_conditions(conditions, "groups.layer_group_id IN (?)", layer_groups.collect(&:id))
      
      # people visible from above
      visible_from_above_groups = ['']
      collapse_groups_to_highest(layer_groups) do |layer_group|
        or_conditions(visible_from_above_groups, 
                      'groups.lft >= ? AND groups.rgt <= ?', 
                      layer_group.left, 
                      layer_group.rgt)
      end
      
      visible_role_types = Role.visible_types.collect(&:sti_name)
      visible_from_above_groups[0] = "(#{visible_from_above_groups.first}) AND roles.type IN (?)"
      visible_from_above_groups << visible_role_types
      or_conditions(conditions, *visible_from_above_groups)
    end
    
    # people in same group
    or_conditions(conditions, 'groups.id IN (?)', user.groups.collect(&:id))
    
    Person.only_public_data.joins(roles: :group).where(conditions).uniq
  end
  
  # If group B is a child of group A, B is collapsed into A.
  # e.g. input [A,B] -> output A
  def collapse_groups_to_highest(layer_groups)
    layer_groups.each do |group|
      unless layer_groups.any? {|g| g.is_ancestor_of?(group) }
        yield group
      end
    end
  end
 
  def or_conditions(conditions, clause, *args)
    if conditions.first.present?
      conditions.first << " OR "
    end
    conditions.first << "(#{clause})"
    conditions.push(*args)
  end
  
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
