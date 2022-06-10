# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

module MailingLists
  module BulkMail
    class SenderRejectedMessageJob < BaseMessageJob

      def perform
        send(reply_message)
      end

      private

      def send(mail)
        if defined?(ActionMailer::Base)
          ActionMailer::Base.wrap_delivery_behavior(mail)
        end

        # set Return-Path as recommended in: https://stackoverflow.com/a/154794
        mail.header['Return-Path'] = '<>'
        mail.deliver
        @message.update!(raw_source: nil)
      end

      def reply_message
        list = list_address
        from = no_reply_address
        source_mail.reply do
          body "Du bist leider nicht berechtigt auf die Liste #{list} zu schreiben."
          from from
        end
      end

    end
  end
end
