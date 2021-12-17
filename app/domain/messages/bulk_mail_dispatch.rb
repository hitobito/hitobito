# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class BulkMailDispatch
    delegate :update, :success_count, to: '@message'

    BULK_SIZE = Settings.email.bulk_mail.bulk_size
    BATCH_TIMEOUT = Settings.email.bulk_mail.batch_timeout
    RETRY_AFTER_ERROR = [5.minutes, 10.minutes].freeze
    INVALID_EMAIL_ERRORS = ['Domain not found',
                            'Recipient address rejected',
                            'Bad sender address syntax'].freeze

    def initialize(message)
      mailing_list = message.mailing_list

      @message = message
      @people = mailing_list.people
      @labels = mailing_list.labels
      @now = Time.current
    end

    def run
      if @message.message_recipients.exists?
        deliver_mails
      else
        init_recipient_entries
      end
    end

    private

    def deliver_mails
      @message.smtp_envelope_to = next_recipients

      begin
        @message.deliver
        update_recipients_state(:sent)
      rescue => e
        if invalid_email?(e)
          reject_failing_recipients(error)
        else
          retry_delivery
        end
      end
    end

    def init_recipient_entries
      recipients = []
      address_list.each do |address|
        recipient_attrs = { message_id: @message.id,
                            created_at: @now,
                            person_id: address[:person_id],
                            email: address[:email] }

        if valid?(address[:email])
          recipient_attrs.merge!(state: :pending)
        else
          recipient_attrs.merge!(state: :failed,
                                 error: "Invalid email")
        end

        recipients << recipient_attrs
      end

      MessageRecipient.insert_all(recipients)
    end

    def retry_delivery
      if @retry >= 2
        failed_count = @message.message_recipients.where(state: :failed).count

        # TODO: Where to display or log failed recipients for initial sender?
        # log_info("aborting delivery for remaining #{failed_count} recipients: #{error_message}")

        return
      else

      end
    end


    def update_recipients_state(state)
      next_recipients.update_all(state: state)
    end

    def invalid_email?(error)
      INVALID_EMAIL_ERRORS.any? { |msg| error.message =~ Regexp.new(msg) }
    end

    def valid?(email)
      Truemail.valid?(email)
    end

    def address_list
      Messages::BulkMail::AddressList.new(@people, @labels).entries
    end

    def next_recipients
      @message.message_recipients.where(state: :pending).limit(BULK_SIZE)
    end

    def reject_failing_recipients(error)
      failed_recipients = next_recipients.find { |r| error.message.include?(r) }
      # if we cannot extract email from error message, raise
      raise error unless failed_recipients.present?

      failed_recipients.update_all(state: :failed, error: error.message)

      next_recipients.reload
    end
  end
end
