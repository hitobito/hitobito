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
    RETRY_AFTER_ERROR = [5.minutes, 10.minutes].freeze
    INVALID_EMAIL_ERRORS = ['Domain not found',
                            'Recipient address rejected'].freeze

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

    def deliver # rubocop:disable Metrics/MethodLength
      return if @recipients.blank?

      prepare_message

      if defined?(ActionMailer::Base)
        ActionMailer::Base.wrap_delivery_behavior(@message)
      end

      yield if block_given?

      log_info("starting bulk send to #{@recipients.count} recipients")

      @slices = (@recipients.count / BULK_SIZE.to_f).ceil
      @current_slice = 0

      @recipients.each_slice(BULK_SIZE).with_index do |r, i|
        break if @abort
        @current_slice += 1
        log_info("sending #{@current_slice}/#{@slices} blocks with #{BULK_SIZE} recipients")
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
      return if recipients.blank?
      @message.smtp_envelope_to = recipients
      begin
        @message.deliver
        @succeeded_recipients += recipients
        @retry = 0
      rescue => e
        retry_or_abort(e, recipients)
      end
    end

    def retry_or_abort(error, recipients) # rubocop:disable Metrics/MethodLength
      if invalid_email?(error)
        recipients = reject_failing(error, recipients)
      else
        # raise error if initial deliver fails.
        # if running inside delayed job this retriggers
        # current job at a later time.
        unless @previous_success
          log_info("initial send failed: #{error.message}")
          raise error
        end

        if @retry >= 2
          abort_delivery(error.message)
          return
        else
          retry_after_sleep(error)
        end
      end
      batch_deliver(recipients)
    end

    def retry_after_sleep(error)
      @retry += 1
      retry_in = RETRY_AFTER_ERROR[@retry - 1]
      log_info("error at #{@current_slice}/#{@slices} send blocks, " \
               "retrying in #{retry_in / 60}mins: #{error.message}")
      sleep retry_in
    end

    def reject_failing(error, recipients)
      failed_email = recipients.find { |r| error.message.include?(r) }
      # if we cannot extract email from error message, raise
      unless failed_email.present? && recipients.include?(failed_email)
        raise error
      end
      log_info "Rejected recipient #{failed_email} with #{error}"
      @failed_recipients << [failed_email, error.message]
      recipients.reject { |r| r =~ /#{failed_email}/ }
    end

    def invalid_email?(error)
      INVALID_EMAIL_ERRORS.any? { |msg| error.message =~ Regexp.new(msg) }
    end

    def abort_delivery(error_message)
      @abort = true
      failed = @recipients - @succeeded_recipients
      log_info("aborting delivery for remaining #{failed.count} " \
               "recipients: #{error_message}")
      failed.each do |r|
        @failed_recipients << [r, error_message]
      end
    end

    def delivery_report
      @success_count = @succeeded_recipients.count
      log_info("delivered to #{@success_count}/#{@recipients.count} " \
               "recipients, #{@failed_recipients.count} failed")
      delivery_report_mail if @delivery_report_to
    end

    def delivery_report_mail
      DeliveryReportMailer.
        bulk_mail(@delivery_report_to, @message,
                  @success_count, Time.zone.now,
                  @failed_recipients).deliver_now
    rescue => e
      log_info('Delivery report for bulk mail to ' \
               "#{@delivery_report_to} could not be delivered: #{e.message}")
      raise e unless Rails.env.production?
    end

    def log_info(info)
      logger.info("#{log_prefix} #{info}")
    end

    def log_prefix
      @log_prefix ||= "BULK MAIL #{@envelope_sender} '#{@message.subject.to_s[0..20]}' |"
    end

    def logger
      Delayed::Worker.logger || Rails.logger
    end

    def apply_headers
      headers.each do |k, v|
        @message[k] = v
      end
    end

  end
end
