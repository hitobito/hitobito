# encoding: utf-8

#  Copyright (c) 2012-2018, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailRelay

  class BulkMail

    attr_accessor :headers

    BULK_SIZE = Settings.email.bulk_mail.bulk_size
    BATCH_TIMEOUT = Settings.email.bulk_mail.batch_timeout
    RETRY_AFTER_ERROR = [5.minutes, 30.minutes]
    EMAIL_REGEX = /([\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+)/i
    DOMAIN_NOT_FOUND_REGEX = /Domain not found/i

    def initialize(message, envelope_sender, delivery_report_to, recipients)
      @message = message
      @envelope_sender = envelope_sender
      @recipients = IdnSanitizer.sanitize(recipients)
      @delivery_report_to = delivery_report_to
      @headers = {}
      @failed_recipients = []
      @succeeded_recipients = []
      @retry = 0
    end

    def deliver(&block)
      return unless @recipients.present?

      prepare_message

      if defined?(ActionMailer::Base)
        ActionMailer::Base.wrap_delivery_behavior(@message)
      end

      yield if block_given?

      @recipients.each_slice(BULK_SIZE).with_index do |r, i|
        break if @abort
        batch_deliver(r)
        @previous_success = true
        sleep BATCH_TIMEOUT.to_i unless last_slice?(i)
      end
      delivery_report
    end

    private

    def last_slice?(i)
      @recipients.size / BULK_SIZE == i
    end

    def prepare_message
      apply_headers

      # Set sender to actual server to satisfy SPF:
      # http://www.openspf.org/Best_Practices/Webgenerated
      @message.sender = @envelope_sender
      @message.smtp_envelope_from = @envelope_sender
    end

    def batch_deliver(recipients)
      return unless recipients.present?
      @message.smtp_envelope_to = recipients
      begin
        @message.deliver
        @succeeded_recipients += recipients
        @retry = 0
      rescue => e
        retry_or_abort(e, recipients)
      end
    end

    def retry_or_abort(error, recipients)
      if domain_not_found_error?(error)
        recipients = reject_failing(error, recipients)
      else
        # raise error if initial deliver fails.
        # if running inside delayed job this retriggers
        # current job at a later time.
        raise error unless @previous_success

        if @retry >= 2
          abort_delivery(error.message)
          return
        else
          @retry += 1
          sleep RETRY_AFTER_ERROR[@retry-1]
        end
      end
      batch_deliver(recipients)
    end

    def reject_failing(error, recipients)
      failed_email = error.message[EMAIL_REGEX]
      # if we cannot extract email from error message, raise
      unless failed_email.present? && recipients.include?(failed_email)
        raise error
      end
      @failed_recipients << [failed_email, error.message]
      recipients.reject {|r| r =~ /#{failed_email}/ }
    end

    def domain_not_found_error?(error)
      error.is_a?(Net::SMTPServerBusy) &&
        error.message =~ DOMAIN_NOT_FOUND_REGEX
    end

    def abort_delivery(error_message)
      @abort = true
      failed = @recipients - @succeeded_recipients
      failed.each do |r|
        @failed_recipients << [r, error_message]
      end
    end

    def delivery_report
      success_count = @succeeded_recipients.count
      delivered_at = DateTime.now
      begin
        DeliveryReportMailer.
          bulk_mail(@delivery_report_to, @message, success_count, delivered_at, @failed_recipients).
          deliver_now
      rescue => e
        logger.info("Delivery report for bulk mail to \
                    #{envelope_to} could not be delivered: #{e.message}")
        raise e unless Rails.env.production?
      end
    end

    def apply_headers
      headers.each do |k, v|
        @message[k] = v
      end
    end

  end
end
