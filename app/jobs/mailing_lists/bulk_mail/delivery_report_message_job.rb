# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module MailingLists
  module BulkMail
    class DeliveryReportMessageJob < BaseMessageJob

      delegate :message_recipients, to: '@message'

      def perform
        delivery_report_mail
      end

      private

      def delivery_report_mail
        DeliveryReportMailer
          .bulk_mail(report_recipient, list_address, @message.subject,
                     success_count, @message.updated_at, failed_recipients)
          .deliver_now
      rescue => e
        log_info('Delivery report for bulk mail to ' \
                 "#{@delivery_report_to} could not be delivered: #{e.message}")
        raise e unless Rails.env.production?
      end

      def failed_recipients
        message_recipients.where(state: :failed).pluck(:email, :error)
      end

      def success_count
        message_recipients.where(state: :sent).count
      end

      def report_recipient
        @message.mail_from
      end

    end
  end
end
