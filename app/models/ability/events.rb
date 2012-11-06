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
      can_manage_event?(event) ||
      events_with_permission(:contact_data).include?(event.id)
    end
    
    can :application_market, Event do |event| 
      can_create_event?(event)
    end
    
    can :qualify, Event do |event| 
      can_create_event?(event) ||
      events_with_permission(:qualify).include?(event.id) 
    end

      
    ### COURSES
    if modify_permissions? 
      can :manage_courses, Person do |person|
        course_groups = Group.can_offer_courses
        contains_any?(groups_group_full, collect_ids(course_groups)) || 
          contains_any?(layers_full, course_groups.collect(&:layer_group_id)) 
      end
    end

    
    ### PARTICIPATIONS
    can :show, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_manage_event?(participation.event) ||
      events_with_permission(:contact_data).include?(participation.event_id) ||
      (participation.application_id? && can_approve_application?(participation))
    end
    
    can [:print, :show_details], Event::Participation do |participation|
      participation.person_id == user.id ||
      can_manage_event?(participation.event)
    end
      
    # create is only invoked by people who wish to
    # apply for an event themselves. A participation for somebody
    # else is created through event roles. 
    # As an exception, participants may be created by an AST
    can :create, Event::Participation do |participation|
      participation.event.application_possible? && 
      ((participation.person_id == user.id) || can_create_event?(participation.event))
    end
    
    # regular people can only create (but not update) their participations 
    can :update, Event::Participation do |participation|
      can_manage_event?(participation.event)
    end
    
    # only participations with applications are destroyed directly
    # other participations are destroyed via destroy of the last event role.
    can :destroy, Event::Participation do |participation|
      can_create_event?(participation.event)
    end
  
    ### EVENT ROLES
        
    can :manage, Event::Role do |role|
      can_manage_event?(role.participation.event)
    end
    
    ### EVENT APPLICATION
    can :show, Event::Application do |application|
      participation = application.participation
      participation.person_id == user.id ||
       can_create_event?(participation.event) ||
       (participation.application_id? && can_approve_application?(participation))
    end
    
    can [:approve, :reject], Event::Application do |application|
      can_approve_application?(application.participation)
    end
    
    ### EVENT KINDS
    if admin
      can :manage, Event::Kind
    end
    
  end
  
  private
  # method is overriden in jubla wagon
  def can_update_event?(event)
    can_manage_event?(event)
  end
  
  def can_manage_event?(event)
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
  
  def can_approve_application?(participation)
    confirm_layer_ids = layer_ids(user.groups_with_permission(:approve_applications))
    confirm_layer_ids.present? &&
     contains_any?(confirm_layer_ids, participation.person.groups_hierarchy_ids)
  end
  
  def events_with_permission(permission)
    @events_with_permission ||= {}
    @events_with_permission[permission] ||= find_events_with_permission(permission)
  end
  
  def find_events_with_permission(permission)
    @participations ||= user.event_participations.includes(:roles).to_a
    @participations.select {|p| p.roles.any? {|r| r.class.permissions.include?(permission) }}.
                    collect(&:event_id)
  end
  
  
end
