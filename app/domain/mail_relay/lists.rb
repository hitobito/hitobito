module MailRelay
  class Lists < Base

    # If the email sender was not allowed to post messages, this method is called.
    def reject_not_allowed
      if sender_email.present?
        reply = message.reply do
          body "Du bist nicht berechtigt, auf diese Liste zu schreiben."
        end
        deliver(reply)
      end
    end

    # If the email is sent to an address that is not a valid relay, this method is called.
    def reject_not_existing
      Rails.logger.info("#{Time.now.strftime('%FT%T%z')}: Ignored email from #{sender_email} for #{envelope_receiver_name}")
    end

    # Is the mail sent to a valid relay address?
    def relay_address?
      mailing_list.present?
    end

    # Is the mail sender allowed to post to this address?
    def sender_allowed?
      sender_is_additional_sender? ||
      sender_is_list_administrator? ||
      (mailing_list.subscribers_may_post? && sender_is_list_member?)
    end

    # List of receiver email addresses for the resent email.
    def receivers
      mailing_list.people.collect(&:email).select(&:present?)
    end

    def mailing_list
      @mailing_list ||= begin
        if mail_name = envelope_receiver_name
          MailingList.where(mail_name: mail_name).first
        end
      end
    end

    def sender
      @sender ||= Person.where(email: sender_email).first
    end

    private

    def deliver(message)
      Rails.logger.info("#{Time.now.strftime('%FT%T%z')}: Relaying email from #{sender_email} for #{envelope_receiver_name} to #{message.destinations.size} people")

      # Set sender to actual server to satisfy SPF: http://www.openspf.org/Best_Practices/Webgenerated
      message.sender = "#{envelope_receiver_name}@#{Settings.email.list_domain}"
      message.header['List-Id'] = "#{envelope_receiver_name}.#{Settings.email.list_domain}"
      super
    end

    def sender_is_additional_sender?
      mailing_list.additional_sender.to_s.split(',').collect(&:strip).include?(sender_email)
    end

    def sender_is_list_administrator?
      sender.present? &&
      Ability.new(sender).can?(:update, mailing_list)
    end

    def sender_is_list_member?
      sender.present? &&
      mailing_list.people.where(id: sender.id).exists?
    end
  end
end