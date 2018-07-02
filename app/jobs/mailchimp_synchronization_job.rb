class MailchimpSynchronizationJob < BaseJob

  self.parameters = [:mailing_list_id]

  def initialize(mailing_list_id)
    super()
    @mailing_list_id = mailing_list_id
  end

  def perform
    Synchronize::Mailchimp.synchronize(@mailing_list_id)
  end

  private

  # def send_mail(recipient, file, format)
  #   MailchimpSynchronizationsMailer.completed(recipient, list).deliver_now
  # end

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
