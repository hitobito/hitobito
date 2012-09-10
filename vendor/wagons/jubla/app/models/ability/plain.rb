class Ability::Plain < Ability::Base
  def initialize(user)
    super(user)
    
    
    can :read, Group
    
    
    if show_person_permissions?
      # View all person details
      can :show, Person do |person|
        # user has group_full, person in same group
        contains_any?(person.groups, groups_group_full) ||
        
        (layers_read.present? && (
          # user has layer_full or layer_read, person in same layer
          contains_any?(layers_read, person.layer_groups) ||
  
          # user has layer_full or layer_read, person below layer and visible_from_above
          contains_any?(layers_read, person.above_groups_visible_from)
        ))
      end
    end
      
    if manage_person_permissions?
      can :manage, Person do |person|
        # user has group_full, person in same group
        contains_any?(person.groups, groups_group_full) ||
        
        (layers_full.present? && (
          # user has layer_full, person in same layer
          contains_any?(layers_full, person.layer_groups) ||
          
          # user has layer_full, person below layer and visible_from_above
          contains_any?(layers_full, person.above_groups_visible_from)
        ))
      end
      
      can :manage, Group do |group|
        # user has group_full for this group
        groups_group_full.include?(group) ||
        
        (layers_full.present? && 
         # user has layer_full, group in same layer
         contains_any?(layers_full, group.layer_groups)
        )
      end
      
    end
  end
end