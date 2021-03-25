# frozen_string_literal: true

#  Copyright (c) 2012-2021, Die Mitte Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  class TextMessageDeliveryReportJob < BaseJob

    def initialize(message_id)
      @message = Message::TextMessage.find(message_id)
    end

    def perform
      recipients = @message.message_recipients
      recipient_ids = recipients.collect(&:id)
      report = client.delivery_reports(recipient_ids: recipient_ids)
      process(report)
      @message.update_message_status!
    end

    private

    def process(report)
      if not_ok?(report)
        abort_dispatch(report, recipients)
      else
        recipients.each do |r|
          r_report = recipient_report(report, r)
          update_recipient(r, *state_and_error_from_report(r_report))
        end
      end
    end

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

    def abort_dispatch(report, recipients)
      recipients.update_all(state: 'failed', error: report[:message]) # rubocop:disable Rails/SkipsModelValidations Performance-Optimization
    end

    def not_ok?(status)
      !status[:status].eql?(:ok)
    end

    def client
      @client ||= Messages::TextMessageProvider::Base.init(config: provider_config)
    end

    def group
      @group ||= @message.mailing_list.group
    end

    def provider_config
      s = group.settings(:text_message_provider)
      s.originator = group.name if s.originator.blank?
      s
    end
  end
end
