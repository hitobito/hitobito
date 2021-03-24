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
          update_recipient(r, *state_and_error_from_report(recipient_report(report, r)))
        end
      end
    end

    private

    def recipient_report(report, recipient)
      report.fetch(:delivery_reports, {})[recipient.id.to_s]
    end

    def state_and_error_from_report(report)
      return ['failed', 'unknown'] unless report # rubocop:disable Style/WordArray the structure should match the other return values
      return ['sent', nil] if report[:status].eql?(:ok)

      ['failed', report[:status_message]]
    end

    def update_recipient(recipient, state, error)
      recipient.update!(state: state, error: error)
    end

    def abort_dispatch(status, recipient_list)
      update_recipients(recipient_list, state: 'failed', error: status[:message])
    end

    def not_ok?(status)
      !status[:status].eql?(:ok)
    end
  end
end
