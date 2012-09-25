class Ability
  include Ability::Common
  
  def initialize(user)
    super(user)
    
    ### GROUPS
    
    can :read, Group
        
    if modify_permissions?
      can :create, Group do |group|
        # BEWARE! Always pass a Role instance to create for correct abilities
        group.parent.present? &&
        can_create_or_destroy_group?(group.parent)
      end
      
      can :destroy, Group do |group|
        can_destroy_group?(group)
      end
      
      can :update, Group do |group|
        can_update_group?(group)
      end
      
      if layers_full.present?
        can :modify_superior, Group do |group|
          contains_any?(layers_full, group.layer_groups - [group.layer_group])
        end
      end
    end
    
    can :index_people, Group do |group|
      can_index_people?(group)
    end
    
    can :external_people, Group do |group|
      user.groups.include?(group) ||
      (layers_read.present? && 
       layers_read.include?(group.layer_group))
    end
    
    
    ### ROLES
    
    if modify_permissions?
      can :create, Role do |role|
        # BEWARE! Always pass a Role instance to create for correct abilities
        can_update_group?(role.group)
      end
    
      can :manage, Role do |role|
        can_modify_role?(role)
      end
    end
    
    
    ### PEOPLE
    
    can :query, Person

    # Everybody may theoretically access the index page, but only the accessible people will be displayed.
    # Check links to :index with can?(:index_people, @group) or can?(:external_people, @group)
    can [:index, :external], Person
    
    can :show, Person do |person|
      can_show_person?(person)
    end
    
    if detail_person_permissions?
      # View all person details
      can :show_details, Person do |person| 
        can_detail_person?(person)
      end
    end
    can :show_details, Person do |person|
      person.id == user.id
    end
    
    if modify_permissions?
      can :create, Person
      can :modify, Person do |person| 
        can_modify_person?(person)
      end
    end
    can :modify, Person do |person|
      person.id == user.id
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
     # user has layer_full, group in same layer or below
     contains_any?(layers_full, group.layer_groups)
  end

  def can_create_group?(group)
    layers_full.present? && 
     # user has layer_full, group in same layer or below
     contains_any?(layers_full, group.layer_groups)
  end
  
  def can_destroy_group?(group)
    can_create_group?(group) && !(groups_layer_full.include?(group) || layers_full.include?(group))
  end
  
  def can_index_people?(group)
    user.groups.include?(group) ||
    layers_read.present? && (
      layers_read.include?(group.layer_group) ||
      contains_any?(layers_read, group.layer_groups)
    ) ||
    user.contact_data_visible?
  end
  
  def can_show_person?(person)
    # both have contact data visible
    (person.contact_data_visible? && user.contact_data_visible?) ||
    # person in same group
    contains_any?(person.groups, user.groups) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, person.layer_groups) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, person.above_groups_visible_from)
    ))
  end
  
  def can_detail_person?(person)
    # user has group_full, person in same group
    contains_any?(person.groups, groups_group_full) ||
    
    (layers_read.present? && (
      # user has layer_full or layer_read, person in same layer
      contains_any?(layers_read, person.layer_groups) ||

      # user has layer_full or layer_read, person below layer and visible_from_above
      contains_any?(layers_read, person.above_groups_visible_from)
    ))
  end
  
  def can_modify_person?(person)
    # user has group_full, person in same group
    contains_any?(person.groups, groups_group_full) ||
    
    (layers_full.present? && (
      # user has layer_full, person in same layer
      contains_any?(layers_full, person.layer_groups) ||
      
      # user has layer_full, person below layer and visible_from_above
      contains_any?(layers_full, person.above_groups_visible_from)
    ))
  end
  
  def can_modify_role?(role)
    # user has group_full, role in same group
    groups_group_full.include?(role.group) ||
    
    (layers_full.present? && (
      # user has layer_full, role in same layer
      layers_full.include?(role.group.layer_group) ||
      
      # user has layer_full, role below layer and visible_from_above
      (role.class.visible_from_above && 
       contains_any?(layers_full, role.group.hierarchy))
    ))
  end
  
  def detail_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present? || @groups_layer_read.present?
  end
  
end
