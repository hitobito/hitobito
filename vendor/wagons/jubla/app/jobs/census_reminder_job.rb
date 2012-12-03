class CensusReminderJob < BaseJob
    
  attr_reader :census, :sender
  
  def initialize(sender, census, flock)
    @census = census
    @sender = sender.email
    @flock_id = flock.id
  end
  
  def perform
    r = recipients
    CensusMailer.reminder(sender, census, r, flock, state_agency).deliver if r.present?
  end
  
  def recipients
    flock.people.only_public_data.
                 where(roles: {type: Group::Flock::Leader.sti_name}).
                 uniq
  end
  
  def flock
    @flock ||= Group::Flock.find(@flock_id)
  end
  
  def state_agency
    state = flock.state
    state.children.where(type: state.contact_group_type.sti_name).first
  end
end