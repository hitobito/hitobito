# frozen_string_literal: true

#  Copyright (c) 2022, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Messages
    module BulkMail
      class MailFactory
        def initialize(bulk_mail_message)
          # ruby mail: https://rubygems.org/gems/mail
          @mail = Mail.new(bulk_mail_message.raw_source)
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
          @mail['Reply-To'] = sender_from
          @mail['Return-Path'] = sender_from
        end

        def sender_from
          @mail.from
        end
      end
    end
  end
