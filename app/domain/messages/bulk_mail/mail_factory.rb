# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
  module BulkMail
    class MailFactory
      def initialize(bulk_mail_message)
        @bulk_mail_message = bulk_mail_message
        # ruby mail: https://rubygems.org/gems/mail
        @mail = Mail.new(@bulk_mail_message.raw_source)
        set_headers
      end

      def deliver
        @mail.deliver
      end

      def to(recipient_emails)
        @mail.smtp_envelope_to = recipient_emails
      end

      private

      def set_headers
        @mail['Reply-To'] = source_mail_sender
        @mail['Return-Path'] = source_mail_sender
        @mail.smtp_envelope_from = mailing_list_address
      end

      def source_mail_sender
        @source_mail_sender ||= @mail.from
      end

      def mailing_list_address
        @bulk_mail_message.mailing_list.mail_address
      end
    end
  end
end
