# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::BulkMail
  class BounceHandler
    MAX_BOUNCE_AGE = 24.hours

    def initialize(imap_bounce_mail, bulk_mail_bounce, mailing_list)
      @bulk_mail_bounce = bulk_mail_bounce
      @imap_mail = imap_bounce_mail
      @mailing_list = mailing_list
    end

    def process
      action = perform_analyzed_action!

      if source_message.blank? || source_message_outdated?
        reject_bounce
        return action
      end

      @bulk_mail_bounce.update!(bounce_parent: source_message,
        raw_source: @imap_mail.raw_source)
      log_info("Forwarding bounce message for list #{@mailing_list.mail_address} " \
               "to #{source_message.mail_from}")

      MailingLists::BulkMail::BounceMessageForwardJob.new(@bulk_mail_bounce).enqueue!

      action
    end

    def perform_analyzed_action!
      action = analyze_diagnostic_codes(Array(@imap_mail.diagnostic_code)) || :unknown
      apply_action(action)
      action
    rescue NoBounceRecipientDetected
      notify_sentry(:no_recipient, action)
      :unknown
    end

    def apply_action(action)
      case action
      when :block then block_bounce
      when :continue then true
      when :register then record_bounce
      when :internal_error then notify_sentry(:internal_error, action)
      else
        record_bounce
        notify_sentry(:unknown_code, action)
      end
    end

    def analyze_diagnostic_codes(codes)
      codes
        .map { |code| analyze_diagnostic_code(code) }
        .min_by { |action| Settings.email.bounces.diagnostic_codes.keys.index(action) }
    end

    def analyze_diagnostic_code(code)
      return :unknown if code.blank?

      cleaned_code = code.squish
      grouped_codes = Settings.email.bounces.diagnostic_codes

      grouped_codes.keys.detect do |action|
        grouped_codes[action].any? do |pattern|
          Regexp.new(pattern).match? cleaned_code
        end
      end || :unknown
    end

    private

    def source_message
      parent_uid = bounce_hitobito_message_uid

      return nil if parent_uid.blank?

      Message::BulkMail.find_by(uid: parent_uid)
    end

    def bounce_hitobito_message_uid
      @imap_mail.bounce_hitobito_message_uid
    end

    def source_message_outdated?
      outdated_at = DateTime.now - MAX_BOUNCE_AGE
      source_message.created_at < outdated_at
    end

    def log_info(text)
      logger.info Retriever::LOG_PREFIX + text
    end

    def logger
      Delayed::Worker.logger || Rails.logger
    end

    def record_bounce
      bounced_mails = @imap_mail.bounced_mail_addresses

      raise MailingLists::BulkMail::NoBounceRecipientDetected, @imap_mail if bounced_mails.empty?

      bounced_mails.map do |email|
        ::Bounce.record(email, mailing_list_id: source_message&.mailing_list_id)
      end
    end

    def block_bounce
      record_bounce.each(&:block!)
    end

    def reject_bounce
      log_info("Ignoring unkown or outdated bounce message for list #{@mailing_list.mail_address}")

      @bulk_mail_bounce.mail_log.update!(status: :bounce_rejected)
      @bulk_mail_bounce.destroy!
    end

    def notify_sentry(message_code, determined_action)
      message = case message_code
      when :internal_error then "A Bounce had an internal error in its Diagnostic Code"
      when :unknown_code then "A Bounce had a previously unknown Diagnostic Code"
      when :no_recipient then "A Bounce had an undetectable original recipient"
      end

      Sentry.capture_message(message, logger: "bounce_handler", extra: {
        diagnostic_code: @imap_mail.diagnostic_code,
        message_id: @imap_mail.message_id,
        determined_action: determined_action
      })
    end
  end
end
