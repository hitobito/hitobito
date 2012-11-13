class CensusMailer < ActionMailer::Base
  
  helper StandardHelper
  
  def reminder(sender, census, recipients)
    @census = census
    mail to: recipients, from: sender
  end
  
  def invitation(census, recipients)
    @census = census
    mail to: Settings.email_mass_recipient, bcc: recipients
  end
  
end