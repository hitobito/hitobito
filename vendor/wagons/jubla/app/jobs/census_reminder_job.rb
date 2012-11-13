class CensusReminderJob < BaseJob
    
  attr_reader :census, :sender
  
  def initialize(sender, census, flock)
    @census = census
    @sender = sender.email
    @flock_id = flock.id
  end
  
  def perform
    r = recipients
    CensusMailer.reminder(sender, census, r).deliver if r.present?
  end
  
  def recipients
    flock.people.where(roles: {type: Group::Flock::Leader.sti_name}).
                 uniq.
                 pluck(:email).
                 compact
  end
  
  def flock
    Group::Flock.find(@flock_id)
  end
end