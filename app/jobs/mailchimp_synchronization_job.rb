class MailchimpSynchronizationJob < BaseJob

  self.parameters = [:mailing_list_id]

  def initialize(mailing_list_id)
    super()
    @mailing_list_id = mailing_list_id
  end

  def perform
    Synchronize::Mailchimp::Synchronizator.new(mailing_list).call
  end

  private

  def mailing_list
    @mailing_list ||= MailingList.find(@mailing_list_id)
  end
end
