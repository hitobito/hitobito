# encoding: utf-8

#  Copyright (c) 2012-2019, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailRelay
  # A generic email relay object. Retrieves messages from a mail server and resends
  # them to a list of recievers.
  # In subclasses, override the methods #relay_address?, #sender_allowed? and #receivers
  # to constrain which mails are sent to whom.
  #
  # See the .relay_current method for the main fetch loop and #relay for the processing
  # decision tree.
  class Base

    # Number of emails to retrieve in one batch.
    class_attribute :retrieve_count
    self.retrieve_count = 5

    # The local domain where mails are received.
    class_attribute :mail_domain
    self.mail_domain = 'localhost'

    attr_reader :message

    delegate :valid_email?, to: :class

    class << self

      # Retrieve, process and delete all mails from the mail server.
      def relay_current
        loop do
          mails, last_exception = relay_batch
          raise(last_exception) if last_exception.present?
          break if mails.size < retrieve_count
        end
      end

      def relay_batch # rubocop:disable Metrics/MethodLength hopefully temporary, this needs refactoring to handle already processed mails better
        last_exception = nil
        logger = Delayed::Worker.logger || Rails.logger

        mails = Mail.find_and_delete(count: retrieve_count) do |message|
          begin
            new(message).relay
          rescue MailProcessedBeforeError => e
            mail_log = MailLog.find_by(mail_hash: MailLog.build(message).mail_hash)
            if mail_log && mail_log.completed?
              logger.info "Deleting previously processed email from #{message.from}"
            else
              message.mark_for_delete = false
              Airbrake.notify(e)
              Raven.capture_exception(e, logger: 'mail_relay')
            end
          rescue Exception => e # rubocop:disable Lint/RescueException
            message.mark_for_delete = false
            last_exception = MailRelay::Error.new(e.message, message, e)
          end
        end

        [mails || [], last_exception]
      rescue EOFError => e
        logger.warn(e)
        [[], nil]
      end

      # rubocop:disable Rails/Output

      # Use this method in the console to clean up errorenous emails.
      def manually_clear_emails
        Mail.find_and_delete(count: 10) do |message|
          message.mark_for_delete = should_clear_email?(message)
          puts ''
        end
      end

      def valid_email?(email)
        email_address = email.to_s.strip
        email_address.present? && !email_address.ends_with?('<>') && email_address.include?('@')
      end

      private

      def should_clear_email?(message)
        print "Delete message '#{message.subject}' (y/N/i)? "
        case gets.strip.downcase
        when 'y'
          true
        when 'i'
          inspect_message(message)
        else
          false
        end
      end

      def inspect_message(message)
        puts message
        puts "\n\n"
        should_clear_email?(message)
      end

      # rubocop:enable Rails/Output

    end

    def initialize(message)
      @message = message
      @mail_log = init_mail_log(message)
    end

    # Process the given email.
    def relay # rubocop:disable Metrics/MethodLength
      if relay_address?
        if sender_allowed?
          @mail_log.update(status: :bulk_delivering)
          bulk_deliver(message)
          @mail_log.update(status: :completed)
        else
          @mail_log.update(status: :sender_rejected)
          reject_not_allowed
        end
      else
        @mail_log.update(status: :unkown_recipient)
        reject_not_existing
      end
      nil
    end

    # If the email sender was not allowed to post messages, this method is called.
    # Silently ignores the message by default.
    def reject_not_allowed
      # do nothing
    end

    # If the email is sent to an address that is not a valid relay, this method is called.
    # Silently ignores the message by default.
    def reject_not_existing
      # do nothing
    end

    # The receiver account that originally got this email.
    # Returns only the part before the @ sign
    def envelope_receiver_name
      receiver_from_x_header('X-Envelope-To') ||  # old mail server
       receiver_from_x_header('X-Original-To') || # new mail server
       receiver_from_received_header ||

       raise("Could not determine original receiver for email:\n#{message.header}")
    end

    def sender_email
      @sender_email ||= message.from && Array(message.from).first
    end

    # Heuristic method to find actual receiver of the message.
    # May return nil if could not determine.
    def receiver_from_received_header
      if (received = message.received)
        received = received.first if received.respond_to?(:first)
        received.info[/\tfor .*?([^\s<>]+)@[^\s<>]+/, 1]
      end
    end

    # Try to read the envelope receiver from the given header
    def receiver_from_x_header(header_name)
      field = message.header[header_name]
      field.to_s.split('@', 2).first if field
    end

    # Is the mail sent to a valid relay address?
    def relay_address?
      true
    end

    # Is the mail sender allowed to post to this address
    def sender_allowed?
      true
    end

    # List of receiver email addresses for the resent email.
    def receivers
      []
    end

    def envelope_sender
      "#{envelope_receiver_name}@#{mail_domain}"
    end

    def list_id
      "#{envelope_receiver_name}.#{mail_domain}"
    end

    private

    def deliver(message)
      if defined?(ActionMailer::Base)
        ActionMailer::Base.wrap_delivery_behavior(message)
      end
      message.header['Precedence'] = 'list'
      message.header['List-Id'] = list_id
      message.deliver
    end

    def bulk_deliver(message)
      bulk_mail.deliver do
        logger.info("Relaying email from #{sender_email} " \
                    "for list #{envelope_receiver_name} " \
                    "to #{message.smtp_envelope_to.size} people")
      end
    end

    def bulk_mail
      bulk_mail = BulkMail.new(message, envelope_sender, delivery_report_to, receivers)
      bulk_mail.headers['Precedence'] = 'list'
      bulk_mail.headers['List-Id'] = list_id
      bulk_mail
    end

    def logger
      Delayed::Worker.logger || Rails.logger
    end

    # Sends a delivery_report to that address (e.g. sender_email) if set
    def delivery_report_to
      nil
    end

    def init_mail_log(message)
      mail_log = MailLog.build(message)
      if mail_log.exists?
        processed_before_error(mail_log)
        return
      end
      mail_log.mailing_list_name = envelope_receiver_name
      mail_log.save
      mail_log
    end

    def processed_before_error(mail_log)
      msg = "Mail with subject '#{mail_log.mail_subject}' has already been " \
            'processed before and is skipped. Please remove it manually ' \
            "from catch-all inbox and check why it could not be processed.\n" \
            "Mail Hash: #{mail_log.mail_hash}"
      raise MailProcessedBeforeError, msg
    end

  end

  class Error < StandardError
    attr_reader :original
    attr_reader :mail

    def initialize(message, mail, original = nil)
      super(message)
      @mail = mail
      @original = original
    end
  end

  class MailProcessedBeforeError < StandardError; end

end
