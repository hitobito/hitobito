# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module MailingLists
  module BulkMail
    class BounceMessageForwardJob < BaseMailMessageJob
      def perform
        send(bounce_mail)
      end

      private

      def send(mail)
        if defined?(ActionMailer::Base)
          ActionMailer::Base.wrap_delivery_behavior(mail)
        end

        mail.deliver

        @message.mail_log.update!(status: "completed")
        @message.update!(raw_source: nil)
      end

      def bounce_mail
        source_mail.to = bounce_parent_sender_email
        source_mail.sender = no_reply_address
        source_mail.smtp_envelope_from = no_reply_address
        source_mail.from = no_reply_address
        source_mail
      end

      def list_address
        mailing_list.mail_address
      end

      def bounce_parent_sender_email
        bounce_parent.mail_from
      end

      def bounce_parent
        @message.bounce_parent
      end

      def mailing_list
        bounce_parent.mailing_list
      end
    end
  end
end
