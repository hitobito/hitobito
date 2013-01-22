class SendLoginJob < BaseJob
  def initialize(recipient, sender)
    @recipient_id = recipient.id
    @sender_id = sender.id
  end
  
  def perform
    recipient.generate_reset_password_token!
    PersonMailer.login(recipient, sender).deliver
  end
  
  def sender
    @sender ||= Person.find(@sender_id)
  end
  
  def recipient
    @recipient ||= Person.find(@recipient_id)
  end
end