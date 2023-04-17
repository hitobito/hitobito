# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::BulkMail
  class BounceHandler

    MAX_BOUNCE_AGE = 24.hours

    def initialize(imap_mail, bulk_mail_bounce, mailing_list)
      @bulk_mail_bounce = bulk_mail_bounce
      @imap_mail = imap_mail
      @mailing_list = mailing_list
    end

    def process
      if !source_message || outdated?
        reject_bounce
        return
      end

      @bulk_mail_bounce.update!(bounce_parent: source_message,
                                raw_source: @imap_mail.raw_source)
      log_info("Forwarding bounce message for list #{@mailing_list.mail_address} " \
               "to #{source_message.mail_from}")
      MailingLists::BulkMail::BounceMessageForwardJob.new(@bulk_mail_bounce).enqueue!
    end

    private

    def source_message
      parent_uid = bounce_hitobito_message_uid
      Message::BulkMail.find_by(uid: parent_uid)
    end

    def bounce_hitobito_message_uid
      @imap_mail.bounce_hitobito_message_uid ||
        @imap_mail.auto_response_hitobito_message_uid
    end

    def outdated?
      outdated_at = DateTime.now - MAX_BOUNCE_AGE
      source_message.created_at < outdated_at
    end

    def log_info(text)
      logger.info Retriever::LOG_PREFIX + text
    end

    def logger
      Delayed::Worker.logger || Rails.logger
    end

    def reject_bounce
      log_info("Ignoring unkown or outdated bounce message for list #{@mailing_list.mail_address}")

      @bulk_mail_bounce.mail_log.update!(status: :bounce_rejected)
      @bulk_mail_bounce.destroy!
    end

  end
end
