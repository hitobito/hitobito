# frozen_string_literal: true

#  Copyright (c) 2012-2021, CVP Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
    class BulkMailDispatch
        #delegate :update, :success_count, to: '@message'

        # BULK_SIZE = Settings.email.bulk_mail.bulk_size
        # BATCH_TIMEOUT = Settings.email.bulk_mail.batch_timeout
        # RETRY_AFTER_ERROR = [5.minutes, 10.minutes].freeze
        # INVALID_EMAIL_ERRORS = ['Domain not found',
        #                         'Recipient address rejected',
        #                         'Bad sender address syntax'].freeze

        def initialize(message, envelope_sender, delivery_report_to, recipients)
         @message = message
         @envelope_sender = envelope_sender
         @recipients = IdnSanitizer.sanitize(recipients)
         @delivery_report_to = delivery_report_to
         @headers = {}
         #@failed_recipients = []           handle with MessageRecipient status
         #@succeeded_recipients = []        handle with MessageRecipient status
         @retry = 0
        end

        def run
         # init_recipient_entries
         # batch_deliver
         # delivery_report
         # update_message_status
        end 

        private

        def init_recipient_entries
         # MessageRecipient entry, one entry for each sent email
        end 

        def update_message_status
         # checks how many deliveries failed/succeeded
        end 

        def batch_deliver
         # get emails from FileStore
         # deliver to recipients
        end 

        def update_recipients
         # shorthand
        end 

        def abort_dispatch(status, recipient_list)
         #update_recipients
        end

        def recipients_list(recipients)
         # used in abort
        end

        def recipients(state:)
         # shorthand to access state of a recipient
         recipients = @message.message_recipients
         recipients.where(state: state)
        end

        def delivery_report
         log_info("delivered to #{recipients(state: 'sent').count} " \
                  "recipients, #{recipients(state: 'failed').count} failed")
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

    end
end        