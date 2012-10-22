# All abilities around events and participations
module Ability::Events
  
  def define_events_abilities
    
    # TODO: implement wicked event visibility
    can :read, Event
    
    can :update, Event do |event|
      can_update_event?(event)
    end
    
    if modify_permissions?
      # BEWARE! Always pass an Event instance to create for correct abilities when using the can? method
      can [:create, :destroy], Event do |event|
        can_create_event?(event)
      end
    end
    
    can :index_participations, Event do |event|
      can_update_event?(event) ||
      events_with_permission(:contact_data).include?(event.id)
    end
    
    can :application_market, Event do |event| 
      can_create_event?(event)
    end

      
    ### COURSES
    if modify_permissions? 
      can :manage_courses, Person do |person|
        course_groups = Group.can_offer_courses
        contains_any?(groups_group_full,collect_ids(course_groups)) || 
          contains_any?(layers_full, course_groups.collect(&:layer_group_id)) 
      end
    end

    
    ### PARTICIPATIONS
    can :show, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_update_event?(participation.event) ||
      events_with_permission(:contact_data).include?(participation.event_id)
    end
    
    can :show_details, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_update_event?(participation.event)
    end
    
    can :create, Event::Participation do |participation|
      (participation.person_id == user.id &&
       user.groups_hierarchy_ids.include?(participation.event.group_id)) ||
       
      can_update_event?(participation.event)
    end
    
    can :update, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_update_event?(participation.event)
    end
    
    can :destroy, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_update_event?(participation.event)
    end
    
    
    ### EVENT APPLICATION
    
    # regular people can only create their applications 
    can :create, Event::Application do |application|
      participation = application.participation
      participation.person_id == user.id ||
      can_create_event?(participation.event)
    end
    
    can [:update, :destroy], Event::Application do |application|
      participation = application.participation
      can_create_event?(participation.event)
    end
    
    ### EVENT ROLES
        
    can :manage, Event::Role do |role|
      can_update_event?(role.participation.event)
    end
    
    
    ### EVENT KINDS
    if admin
      can :manage, Event::Kind
    end
    
  end
  
  private
  
  def can_update_event?(event)
    event.group && (
    can_create_event?(event) ||
    events_with_permission(:full).include?(event.id) ||
    contains_any?(layers_full, collect_ids(event.group.layer_groups)))
  end
  
  def can_create_event?(event)
    event.group && (
    groups_group_full.include?(event.group_id) ||
    layers_full.include?(event.group.layer_group_id))
  end
  
  def events_with_permission(permission)
    @events_with_permission ||= {}
    @events_with_permission[permission] ||= find_events_with_permission(permission)
      
  end
  
  def find_events_with_permission(permission)
    participations = user.event_participations.includes(:roles).to_a
    participations.select {|p| p.roles.any? {|r| r.class.permissions.include?(permission) }}.
                   collect(&:event_id)
  end
  
  
end
