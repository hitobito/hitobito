module Ability::People
 
  
  def define_people_abilities
    can :query, Person

    # Everybody may theoretically access the index page, but only the accessible people will be displayed.
    # Check links to :index with can?(:index_people, @group)
    can :index, Person, accessible_people do |p| true end
    
    can :show, Person do |person|
      can_show_person?(person)
    end

    can [:show_full, :history], Person do |person|
      can_full_person?(person) ||
      person.id == user.id
    end

    can :show_details, Person do |person|
      can_full_person?(person) || 
      contains_any?(user_groups, collect_ids(person.groups))
    end
    
    if modify_permissions?
      can :create, Person
      can :modify, Person do |person| 
        can_modify_person?(person)
      end
      can :send_password_instructions, Person do |person| 
        can_modify_person?(person) && person.id != user.id &&
          person.login?  && person.email.present?
      end
    end
    can :modify, Person do |person|
      person.id == user.id
    end
     
     
    ### PEOPLE_FILTERS
    
    can :new, PeopleFilter do |filter|
      can_index_people?(filter.group)
    end
    
    can :create, PeopleFilter do |filter|
      layers_full.present? && layers_full.include?(filter.group.layer_group_id)
    end
    
    can :destroy, PeopleFilter do |filter|
      filter.group_id? &&
      layers_full.present? && layers_full.include?(filter.group.layer_group_id)
    end

  end
  
  private
  
  
  def can_index_people?(group)
    user.contact_data_visible? ||
    user_groups.include?(group.id) ||
    layers_read.present? && (
      layers_read.include?(group.layer_group.id) ||
      contains_any?(layers_read, collect_ids(group.layer_groups))
    )
  end
  
  def can_show_person?(person)
    # both have contact data visible
    (person.contact_data_visible? && user.contact_data_visible?) ||
    # person in same group
    contains_any?(collect_ids(person.groups), user_groups) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, person.layer_group_ids) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def can_full_person?(person)
    # user has group_full, person in same group
    contains_any?(groups_group_full, collect_ids(person.groups)) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, person.layer_group_ids) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def can_modify_person?(person)
    # user has group_full, person in same group
    contains_any?(groups_group_full, collect_ids(person.non_restricted_groups)) ||
    
    (layers_full.present? && (
      # user has layer_full, person in same layer
      contains_any?(layers_full, person.non_restricted_groups.collect(&:layer_group_id).uniq) ||
      
      # user has layer_full, person below layer and visible_from_above
      contains_any?(layers_full, collect_ids(person.above_groups_visible_from))
    ))
  end
  
  def full_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present? || @groups_layer_read.present?
  end
  
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
  
end
