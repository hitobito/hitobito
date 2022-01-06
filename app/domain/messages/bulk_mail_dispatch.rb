# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class BulkMailDispatch
    delegate :update, :success_count, to: '@message'

    DELIVERY_RETRIES = 2
    BULK_SIZE = Settings.email.bulk_mail.bulk_size
    BATCH_TIMEOUT = Settings.email.bulk_mail.batch_timeout
    RETRY_AFTER_ERROR = [5.minutes, 10.minutes].freeze

    # @param [Message] message
    # @param [BulkMail::MailFactory] mail_factory
    def initialize(message, mail_factory = nil)
      @message = message
      @mail_factory = mail_factory || BulkMail::MailFactory.new(message)
    end

    def run
      if recipients_generated?(@message)
        recipients = pending_recipients(@message).limit(BULK_SIZE)
        deliver_mails(@mail_factory, recipients, DELIVERY_RETRIES)
      else
        BulkMail::CreateRecipients.new.create!(@message)
      end

      reschedule_unless_none_pending(@message)
    end

    private

    def deliver_mails(mail_factory, recipients, retries)
      delivery = BulkMail::Delivery.new(mail_factory, recipients.map(&:email), retries)

      begin
        delivery.deliver
        succeeded, failed = recipient_ids(recipients, [delivery.succeeded, delivery.failed])

        Rails.logger.info "Sent mails, #{succeeded.length} OK, #{failed.length} failed."

        MessageRecipient.where(id: succeeded).update_all(state: :sent)
        MessageRecipient.where(id: failed).update_all(state: :failed)
      rescue BulkMail::Delivery::RetriesExceeded => e
        # TODO fail cleanly
        raise e
      end
    end

    def reschedule_unless_none_pending(message)
      if pending = pending_recipient_count(message) > 0
        Rails.logger.info "#{pending} recipients pending, rescheduling dispatch job."
        DispatchResult.needs_reenqueue
      else
        Rails.logger.info "All mails sent, BulkMailDispatch complete."
        DispatchResult.finished
      end
    end

    def recipients_generated?(message)
      message.message_recipients.exists?
    end

    def pending_recipients(message)
      message.message_recipients.where(state: :pending)
    end

    def pending_recipient_count(message)
      pending_recipients(message).count
    end

    def recipient_ids(recipients, email_groups)
      by_email = recipients.index_by(&:email)
      email_groups.map { |emails| by_email.values_at(*emails).map(&:id) }
    end
  end
end
