module Event::Qualifier
  
  def self.for(participation)
    qualifier_class(participation).new(participation)
  end
  
  def self.leader_types(event)
    event.class.role_types.select(&:leader)
  end
  
  private
  
  def self.qualifier_class(participation)
    if leader?(participation)
      Event::Qualifier::Leader
    else
      Event::Qualifier::Participant
    end
  end
  
    
  def self.leader?(participation)
    participation.roles.where(type: leader_types(participation.event).map(&:sti_name)).exists?
  end
  
end