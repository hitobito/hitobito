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
        # Preserve original sender in Reply-To so recipients can reply directly to them
        @mail["Reply-To"] = @mail.from
        # Add unique message identifier for tracking and deduplication
        @mail["X-Hitobito-Message-UID"] = @bulk_mail_message.uid
        # Rewrite From header to show message came via mailing list
        @mail.from = sender_via_mailinglist
        # Set SMTP envelope sender to mailing list address for bounce handling
        @mail.smtp_envelope_from = mailing_list_address
        # Set To header if empty (e.g., BCC mails) to ensure RFC-compliant mail
        # that won't be rejected by mail systems like GMX.
        set_undisclosed_recipients if @mail.to.blank?
      end

      # Set To header to 'Undisclosed recipients:;'
      # Uses RFC 5322 group syntax (https://datatracker.ietf.org/doc/html/rfc5322#section-3.4)
      def set_undisclosed_recipients
        # We want to circumvent the normal parsing of address header values of the mail gem.
        # So we use a plain StructuredField instead of the regular ToField and we add the
        # header manually instead of using the setter.
        # The gem's api allows us to replace a header field by name. So we first make sure
        # the header exists, then we replace it with the correct value.
        # Using #insert_field directly without the to header preexisting does not work as
        # StructuredField does not implement the method #<() which is used by #insert_field.
        # @mail.to = ""
        field = Mail::Field.new("To", "Undisclosed recipients:;")
        undisclosed = Mail::OptionalField.new("To", "Undisclosed recipients:;")
        field.instance_variable_set(:@field, undisclosed)
        @mail.header.fields.replace_field(field)
      end

      def sender_via_mailinglist
        name = @mail["from"].display_names.try(:first)
        sender_name = name || @mail.from.first
        "#{sender_name} via #{mailing_list_address} <#{mailing_list_address}>"
      end

      def mailing_list_address
        @bulk_mail_message.mailing_list.mail_address
      end
    end
  end
end
