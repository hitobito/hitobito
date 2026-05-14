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
      action = analyze!

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

    def analyze!
      action = analyze_diagnostic_code(@imap_mail.diagnostic_code)

      case action
      when :block then block_bounce
      when :continue then true
      when :register then record_bounce
      when :internal_error then notify_sentry(:internal_error)
      else
        record_bounce
        notify_sentry(:unknown_code)
      end

      action
    end

    def analyze
      analyze_diagnostic_code(@imap_mail.diagnostic_code)
    end

    def analyze_diagnostic_code(code)
      return :unknown if code.blank?

      grouped_codes = Settings.email.bounces.diagnostic_codes

      grouped_codes.keys.detect do |action|
        grouped_codes[action].detect do |pattern|
          Regexp.new(pattern).match? code.squish
        end
      end || :unknown
    end

    private

    def source_message
      parent_uid = bounce_hitobito_message_uid

      return nil unless parent_uid.present?

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

    def notify_sentry(message_code)
      message = case message_code
      when :internal_error then "A Bounce had a internal error in its Diagnostic Code"
      when :unknown_code then "A Bounce had a previously unknown Diagnostic Code"
      end

      Sentry.capture_message(message, logger: "bounce_handler", extra: {
        diagnostic_code: @imap_mail.diagnostic_code
      })
    end
  end
end
