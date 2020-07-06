# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailRelay
  # The mailing list implementation.
  #
  # A special bouncing mechanism is applied: When relaying an email, the original sender
  # is encoded in the return path, e.g. as my-list+sender=example.com@mail-domain.com.
  # When a receiving server bounces the mail, it is relayed again to the original sender,
  # based on the encoded return path address.
  class Lists < Base

    SENDER_SUFFIX = '-bounces'

    self.mail_domain = Settings.email.list_domain

    class << self
      def personal_return_path(list_name, sender_email, domain = nil)
        # recipient format (before @) must match regexp in #reject_not_existing
        id_suffix = '+' + sender_email.tr('@', '=')
        "#{list_name}#{SENDER_SUFFIX}#{id_suffix}@#{domain || mail_domain}"
      end

      def app_sender_name
        app_sender = Settings.email.sender
        app_sender[/^.*<(.+)@.+\..+>$/, 1] || app_sender[/^(.+)@.+\..+$/, 1] || 'noreply'
      end
    end

    def initialize(message)
      strip_spam_headers(message)
      super(message)
    end

    # If the email sender was not allowed to post messages, this method is called.
    # Do not send reject emails to blank recipients nor for mails
    # sent to the application (noreply) email address (to avoid daemon ping-pong).
    def reject_not_allowed
      if send_reject_message?
        reply = prepare_not_allowed_message
        if valid_email?(reply.to.to_s.strip)
          logger.info("Rejecting email from #{sender_email} for list #{envelope_receiver_name}")
          deliver(reply)
        end
      end
    end

    # If the email is sent to an address that is not a valid relay, this method is called.
    # Forwards bounce messages to the original sender
    def reject_not_existing
      data = envelope_receiver_name.match(/^(.+)#{SENDER_SUFFIX}\+(.+=.+)$/)
      if data && valid_address?(data[1])
        prepare_bounced_message(data[1], data[2])
        logger.info("Relaying bounce from #{message.from} for list #{data[1]} to #{message.to}")
        deliver(message)
      else
        logger.info("Ignored email from #{sender_email} " \
                    "for unknown list #{envelope_receiver_name}")
      end
    end

    def valid_address?(mail_name)
      self.class.app_sender_name == mail_name || MailingList.where(mail_name: mail_name).exists?
    end

    # Is the mail sent to a valid relay address?
    def relay_address?
      mailing_list.present?
    end

    # Sends a delivery_report to sender_email if flag is set
    def delivery_report_to
      sender_email if mailing_list.delivery_report
    end

    # Is the mail sender allowed to post to this address?
    def sender_allowed? # rubocop:disable Metrics/CyclomaticComplexity
      return false unless valid_email?(sender_email)

      mailing_list.anyone_may_post ||
      sender_is_additional_sender? ||
      sender_is_group_email? ||
      sender_is_list_administrator? ||
      (mailing_list.subscribers_may_post? && sender_is_list_member?)
    end

    # List of receiver email addresses for the resent email.
    def receivers
      @mail_log.update(mailing_list: mailing_list)
      Person.mailing_emails_for(mailing_list.people.to_a,
                                mailing_list.labels)
    end

    def mailing_list
      @mailing_list ||= begin
        mail_name = envelope_receiver_name
        MailingList.where(mail_name: mail_name).first if mail_name
      end
    end

    def envelope_sender
      self.class.personal_return_path(envelope_receiver_name, sender_email)
    end

    private

    def prepare_not_allowed_message
      sender = "#{envelope_receiver_name}#{SENDER_SUFFIX}@#{mail_domain}"
      message.reply do
        body 'Du bist nicht berechtigt, auf diese Liste zu schreiben.'
        from sender
      end
    end

    def prepare_bounced_message(list_address, sender_address)
      message.to = sender_address.tr('=', '@')

      env_sender = "#{list_address}#{SENDER_SUFFIX}@#{mail_domain}"
      message.sender = env_sender
      message.smtp_envelope_from = env_sender
    end

    def valid_domain?(domain)
      domain !~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/
    end

    def sender_is_additional_sender?
      additional_senders = mailing_list.additional_sender.to_s
      list = additional_senders.split(/[,;]/).collect(&:strip).select(&:present?)
      sender_domain = sender_email.sub(/^[^@]*@/, '*@')
      # check if the domain is valid, if the sender is in the senders
      # list or if the domain is whitelisted
      list.include?(sender_email) ||
          (valid_domain?(sender_domain) && list.include?(sender_domain))
    end

    def sender_is_group_email?
      group = mailing_list.group
      group.email == sender_email ||
      group.additional_emails.collect(&:email).include?(sender_email)
    end

    def sender_is_list_administrator?
      potential_senders.any? do |sender|
        Ability.new(sender).can?(:update, mailing_list)
      end
    end

    def sender_is_list_member?
      mailing_list.people.where(id: potential_senders.select(:id)).exists?
    end

    def potential_senders
      Person.joins('LEFT JOIN additional_emails ON people.id = additional_emails.contactable_id' \
                   " AND additional_emails.contactable_type = '#{Person.sti_name}'").
             where('people.email = ? OR additional_emails.email = ?', sender_email, sender_email).
             distinct
    end

    def send_reject_message?
      sender_email.present? &&
        envelope_receiver_name != self.class.app_sender_name
    end

    # strip spam headers because they might produce encoding issues
    # (Encoding::UndefinedConversionError)
    def strip_spam_headers(message)
      spam_headers = message.header.select { |field| field.name =~ /^X-DSPAM/i }
      spam_headers.each do |field|
        message.header[field.name] = nil
      end
    end

  end
end
