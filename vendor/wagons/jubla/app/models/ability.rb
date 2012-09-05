class Ability
  include CanCan::Ability
  
  attr_reader :groups_group_full, 
              :groups_layer_full, 
              :groups_layer_read,
              :layers_read,
              :layers_full
              

  def initialize(user)
    init_groups(user)
    
    
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
 
    
    
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user permission to do.
    # If you pass :manage it will apply to every action. Other common actions here are
    # :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on. If you pass
    # :all it will apply to every resource. Otherwise pass a Ruby class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details: https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
  
  private
  
  def init_groups(user)
    @groups_group_full = user.groups_with_permission(:group_full)
    @groups_layer_full = user.groups_with_permission(:layer_full)
    @groups_layer_read = user.groups_with_permission(:layer_read)
    @layers_read = layers(groups_layer_full, groups_layer_read)
    @layers_full = layers(groups_layer_full)
  end
  
  def show_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present? || @groups_layer_read.present?
  end
  
  def manage_person_permissions?
    @groups_group_full.present? || @groups_layer_full.present?
  end
  
  def layers(*groups)
    groups.flatten.collect(&:layer_group).uniq
  end
  
  # Are any items of the existing list present in the list of required items? 
  def contains_any?(required, existing)
    (required & existing).present?
  end
  
  
  class WithGroup < ::Ability
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
        can :deep_search, Person, Person.only_public_data.visible_from_above.in_or_below_layer(group.layer_group)
      elsif user.contact_data_visible?
        can :deep_search, Person, Person.only_public_data.contact_data_visible.in_or_below_layer(group.layer_group)
      end
    end
  end
  
end
