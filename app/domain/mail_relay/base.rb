# frozen_string_literal: true

#  Copyright (c) 2012-2022, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.


module MailRelay
  # A generic email relay object. Retrieves messages from a mail server and resends
  # them to a list of receivers.
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

    attr_reader :message, :mail_log

    delegate :valid_email?, to: :class

    class << self

      def logger
        Delayed::Worker.logger || Rails.logger
      end

      # Retrieve, process and delete all mails from the mail server.
      def relay_current
        loop do
          mails, last_exception = relay_batch
          raise(last_exception) if last_exception.present?
          break if mails.size < retrieve_count
        end
      end

      def relay_batch
        last_exception = nil

        mails = Mail.find_and_delete(count: retrieve_count) do |message|
          proccessed_error = process(message)
          last_exception = proccessed_error if proccessed_error
        end

        [mails || [], last_exception]
      rescue EOFError => e
        logger.warn(e)
        [[], nil]
      end

      def process(message)
        new(message).relay
      rescue MailRelay::MailProcessedBeforeError => e
        processed_before(message, e)
        nil
      rescue Exception => e # rubocop:disable Lint/RescueException
        message.mark_for_delete = false
        MailRelay::Error.new(e.message, message, e)
      end

      def processed_before(message, exception)
        mail_log = MailLog.find_by(mail_hash: MailLog.build(message).mail_hash)
        if mail_log&.completed?
          logger.info "Deleting previously processed email from #{message.from}"
        else
          message.mark_for_delete = false
          Airbrake.notify(exception)
          mail_hash = mail_log.mail_hash
          Raven.capture_exception(exception, logger: 'mail_relay', extra: { mail_hash: mail_hash },
                                             fingerprint: ['{{ default }}', mail_hash])
        end
      end

      def valid_email?(email)
        email.present? && Truemail.valid?(email, with: :regex)
      end
    end

    def initialize(message)
      @message = message
      @mail_log = init_mail_log(message)
    end

    # Process the given email.
    def relay # rubocop:disable Metrics/MethodLength
      if relay_address?
        if sender_valid? && sender_allowed?
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
      receiver_from_x_original_to_header ||
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

    def receiver_from_x_original_to_header
      first_header('X-Original-To').to_s.split('@', 2).first.presence
    end

    def first_header(header_name)
      Array(message.header[header_name]).first
    end

    # Is the mail sent to a valid relay address?
    def relay_address?
      true
    end

    # Is the mail sender allowed to post to this address
    def sender_allowed?
      true
    end

    def sender_valid?
      return true if valid_email?(sender_email)

      # try again AND log if the error persists
      Truemail.validate(sender_email).tap do |validator|
        Rails.logger.info <<~MESSAGE unless validator.result.valid?
          MailRelay: #{sender_email} is not valid: #{validator.result.errors.map { |k, v| "[#{k}] #{v}" }.join(',')}, see MailLog #{@mail_log.mail_hash}.
        MESSAGE
      end
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
      raise MailProcessedBeforeError, mail_log if mail_log.exists?

      mail_log.mailing_list_name = envelope_receiver_name
      mail_log.save
      mail_log
    end

  end
end
