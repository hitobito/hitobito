class MailchimpSynchronizationJob < BaseJob

  def initialize(mailing_list_id)
    super()
    @mailing_list_id = mailing_list_id
  end

  def perform
    Mailchimp::Synchronizator.sync(mailing_list)
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
