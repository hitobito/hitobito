class Event::SendRegisterLoginJob < BaseJob
  
  def initialize(recipient, group, event)
    @recipient_id = recipient.id
    @group_id = group.id
    @event_id = event.id
  end
  
  def perform
    recipient.generate_reset_password_token!
    Event::RegisterMailer.register_login(recipient, group, event).deliver
  end
  
  def recipient
    @recipient ||= Person.find(@recipient_id)
  end
  
  def event
    @event ||= group.events.find(@event_id)
  end
  
  def group
    @group ||= Group.find(@group_id)
  end
end