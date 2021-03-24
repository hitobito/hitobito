# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class TextMessageDeliveryReportJob < BaseJob

    def initialize(message, client)
      super()
      @message = message
      @client = client
    end

    def perform
      recipients = @message.message_recipients.reload
      recipient_ids = recipients.collect(&:id)
      report = @client.delivery_reports(recipient_ids: recipient_ids)
      if not_ok?(report)
        abort_dispatch(report, recipients)
      else
        recipients.each do |r|
          update_recipient(report[:delivery_reports], r)
        end
      end
    end

    private

    def update_recipient(delivery_reports, recipient)
      report = delivery_reports[recipient.id.to_s]
      error = 'unkown'
      if report
        if report[:status].eql?(:ok)
          state = 'sent'
          error = nil
        else
          error = report[:status_message]
        end
      end
      recipient.update!(state: state || 'failed', error: error)
    end

    def abort_dispatch(status, recipient_list)
      update_recipients(recipient_list, state: 'failed', error: status[:message])
    end

    def not_ok?(status)
      !status[:status].eql?(:ok)
    end
  end
end
