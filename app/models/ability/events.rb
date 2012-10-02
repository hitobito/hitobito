# All abilities around events and participations
module Ability::Events
  
  def define_events_abilities

    # TODO: remove temp permissions
    # temp permissions
    can :new, Event
    
    # TODO: implement wicked event visibility
    can :read, Event
    
    can :update, Event do |event|
      can_update_event?(event)
    end
    
    if modify_permissions?
      # BEWARE! Always pass an Event instance to create for correct abilities
      can [:create, :destroy], Event do |event|
        can_create_event?(event)
      end
    end
    
    
    ### PARTICIPATIONS
    
    can :read, Event::Participation do |participation|
      event = participation.event
      participation.person_id == user.id ||
      can_update_event?(event) ||
      events_with_permission(:contact_data).include?(event.id)
    end
    
    can :manage, Event::Participation do |participation|
      participation.person_id == user.id ||
      can_update_event?(participation.event)
    end
    
    
    ### EVENT KINDS
    if admin
      can :manage, Event::Kind
    end
    
  end
  
  private
  
  def can_update_event?(event)
    can_create_event?(event) ||
    events_with_permission(:full).include?(event.id)
  end
  
  def can_create_event?(event)
    groups_group_full.include?(event.group_id) ||
    layers_full.include?(event.group.layer_group_id)
  end
  
  def events_with_permission(permission)
    @events_with_permission ||= {}
    @events_with_permission[permission] ||= 
      user.event_participations.to_a.select {|p| p.class.permissions.include?(permission) }.collect(&:event_id).uniq
  end
  
  
end
