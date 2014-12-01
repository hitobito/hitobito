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
      def personal_return_path(list_name, sender_email)
        # recipient format (before @) must match regexp in #reject_not_existing
        "#{list_name}#{SENDER_SUFFIX}+#{sender_email.gsub('@', '=')}@#{mail_domain}"
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
      if sender_email.present? && envelope_receiver_name != self.class.app_sender_name
        sender = "#{envelope_receiver_name}@#{mail_domain}"
        reply = message.reply do
          body 'Du bist nicht berechtigt, auf diese Liste zu schreiben.'
          from sender
        end
        deliver(reply) unless ['', '<>'].include?(reply.to.to_s.strip)
      end
    end

    # If the email is sent to an address that is not a valid relay, this method is called.
    # Forwards bounce messages to the original sender
    def reject_not_existing
      data = envelope_receiver_name.match(/^(.+)#{SENDER_SUFFIX}\+(.+=.+)$/)
      if data && valid_address?(data[1])
        prepare_reject_message(data[1], data[2])
        deliver(message)
      else
        logger.info("#{Time.now.strftime('%FT%T%z')}: " \
                    "Ignored email from #{sender_email} " <<
                    "for list #{envelope_receiver_name}")
      end
    end

    def prepare_reject_message(list_address, sender_address)
      message.to = sender_address.gsub('=', '@')

      env_sender = "#{list_address}#{SENDER_SUFFIX}@#{mail_domain}"
      message.sender = env_sender
      message.smtp_envelope_from = env_sender
    end

    def valid_address?(mail_name)
      self.class.app_sender_name == mail_name || MailingList.where(mail_name: mail_name).exists?
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
      Person.mailing_emails_for(mailing_list.people.to_a)
    end

    def mailing_list
      @mailing_list ||= begin
        mail_name = envelope_receiver_name
        MailingList.where(mail_name: mail_name).first if mail_name
      end
    end

    def sender
      @sender ||= Person.where(email: sender_email).first
    end

    def envelope_sender
      self.class.personal_return_path(envelope_receiver_name, sender_email)
    end

    private

    def deliver(message)
      logger.info("#{Time.now.strftime('%FT%T%z')}: " \
                  "Relaying email from #{sender_email} " <<
                  "for list #{envelope_receiver_name} " \
                  "to #{message.smtp_envelope_to.size} people")
      super
    end

    def sender_is_additional_sender?
      mailing_list.additional_sender.to_s.split(/[,;]/).collect(&:strip).include?(sender_email)
    end

    def sender_is_list_administrator?
      sender.present? &&
      Ability.new(sender).can?(:update, mailing_list)
    end

    def sender_is_list_member?
      sender.present? &&
      mailing_list.people.where(id: sender.id).exists?
    end

    # strip spam headers because they might produce encoding issues
    # (Encoding::UndefinedConversionError)
    def strip_spam_headers(message)
      spam_headers = message.header.select { |field| field.name =~ /^X-DSPAM/i }
      spam_headers.each do |field|
        message.header[field.name] = nil
      end
    end

    def logger
      Delayed::Worker.logger || Rails.logger
    end
  end
end
