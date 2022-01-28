# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class BulkMailDispatch
    delegate :update, :success_count, :message_recipients, to: '@message'

    DELIVERY_RETRIES = 2
    BULK_SIZE = Settings.email.bulk_mail.bulk_size
    BATCH_TIMEOUT = Settings.email.bulk_mail.batch_timeout
    RETRY_AFTER_ERROR = [5.minutes, 10.minutes].freeze

    def initialize(message, mail_factory = nil)
      @message = message
      @mail_factory = mail_factory || BulkMail::MailFactory.new(message)
    end

    def run
      check_message_state

      if recipients_generated?
        recipients = recipients_by(state: :pending).limit(BULK_SIZE)
        deliver_mails(@mail_factory, recipients, DELIVERY_RETRIES)
      else
        BulkMail::CreateRecipients.new.create!(@message)
      end

      reschedule_unless_none_pending
    end

    private

    def check_message_state
      if @message.pending?
        @message.update!(state: 'processing')
      end
    end

    def deliver_mails(mail_factory, recipients, retries)
      delivery = BulkMail::Delivery.new(mail_factory, recipients.map(&:email), retries)

      begin
        delivery.deliver
        succeeded, failed = recipient_ids(recipients, [delivery.succeeded, delivery.failed])

        log "Sent mails, #{succeeded.length} OK, #{failed.length} failed."

        message_recipients.where(id: succeeded).update_all(state: :sent)
        message_recipients.where(id: failed).update_all(state: :failed)
      rescue BulkMail::Delivery::RetriesExceeded => e
        abort_smtp_error
      end
    end

    def abort_smtp_error
      message_recipients
        .where
        .not(state: :sent)
        .update_all(state: :failed, error: 'SMTP server error')
      @message.update!(state: 'failed')
      log 'SMTP server error, BulkMailDispatch aborted.'
    end

    def reschedule_unless_none_pending
      update_message_counts

      if pending_recipient_count > 0
        log "#{pending_recipient_count} recipients pending, rescheduling dispatch job."
        DispatchResult.needs_reenqueue
      else
        finish_dispatch
      end
    end

    def finish_dispatch
      unless @message.failed?
        log 'All mails sent, BulkMailDispatch complete.'
        @message.update!(state: 'finished', raw_source: nil)
      end
      DispatchResult.finished
    end

    def update_message_counts
      success_count = recipients_by(state: :sent).count
      failed_count = recipients_by(state: :failed).count
      @message.update!(success_count: success_count, failed_count: failed_count)
    end

    def recipients_generated?
      message_recipients.exists?
    end

    def recipients_by(state:)
      message_recipients.where(state: state)
    end

    def pending_recipient_count
      recipients_by(state: :pending).count
    end

    def recipient_ids(recipients, emails_by_delivery_status)
      by_email = recipients.index_by(&:email)
      emails_by_delivery_status.map { |emails| by_email.values_at(*emails).map(&:id) }
    end

    def log(info)
      Rails.logger.info info
    end
  end
end
