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
      if group_read_in_this_group? || layer_read_in_same_layer? || user.root?
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
    condition = OrCondition.new
    
    if user.contact_data_visible?
      # people with contact data visible
      condition.or('people.contact_data_visible = ?', true)
    end
    
    if layers_read.present?
      layer_groups = layers(user.groups_with_permission(:layer_full), 
                            user.groups_with_permission(:layer_read))
      
      # people in same layer
      condition.or("groups.layer_group_id IN (?)", layer_groups.collect(&:id))
      
      # people visible from above
      visible_from_above_groups = OrCondition.new
      collapse_groups_to_highest(layer_groups) do |layer_group|
        visible_from_above_groups.or('groups.lft >= ? AND groups.rgt <= ?', 
                                     layer_group.left, 
                                     layer_group.rgt)
      end
      
      query = "(#{visible_from_above_groups.to_a.first}) AND roles.type IN (?)"
      args = visible_from_above_groups.to_a[1..-1] + [Role.visible_types.collect(&:sti_name)]
      condition.or(query, *args)
    end
    
    # people in group with group_read
    if groups_group_read.present?
      condition.or('groups.id IN (?)', groups_group_read)
    end

    # root can access everybody, everybody else can access themselves
    unless user.root?
      condition.or('people.id = ?', user.id)
    end
    
    Person.only_public_data.
           joins(roles: :group).
           where(roles: {deleted_at: nil}, groups: {deleted_at: nil}).
           where(condition.to_a).
           uniq
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
   
  def group_read_in_this_group?
    groups_group_read.include?(group.id)
  end

  def layer_read_in_same_layer?
    layers_read.present? && layers_read.include?(group.layer_group_id)
  end
  
  def layer_read_in_above_layer?
    layers_read.present? && contains_any?(layers_read, collect_ids(group.layer_groups))
  end
end
