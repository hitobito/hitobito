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

        if defined?(ActionMailer::Base)
          ActionMailer::Base.wrap_delivery_behavior(@mail)
        end

        set_headers
      end

      def deliver
        @mail.deliver
      end

      def to(recipient_emails)
        @mail.smtp_envelope_to = recipient_emails
        self
      end

      private

      def set_headers
        @mail['Reply-To'] = @mail.from
        @mail['X-Hitobito-Message-UID'] = @bulk_mail_message.uid
        @mail.from = sender_via_mailinglist
        @mail.smtp_envelope_from = mailing_list_address
      end

      def sender_via_mailinglist
        name = @mail['from'].display_names.first
        "#{name} via #{mailing_list_address} <#{mailing_list_address}>"
      end

      def mailing_list_address
        @bulk_mail_message.mailing_list.mail_address
      end
    end
  end
end
