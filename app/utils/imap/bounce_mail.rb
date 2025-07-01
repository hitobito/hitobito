# frozen_string_literal: true

#  Copyright (c) 2025-2025, Schweizer Wanderwege. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Imap
  class MultiRecipientBounce < StandardError
    def initialize(msg = nil)
      super(msg || "The bounced message seems to concern multiple addresses.")
    end
  end

  class BounceMail < ::Imap::Mail
    # I am sorry for this subclass-wrapper. Reworking this in a way that this always receives
    # a proper "Net::Imap"-compatible mail-object seems to be a huge undertaking.
    #
    # Patches and Refactorings welcome...
    def initialize(imap_mail)
      @imap_mail = imap_mail

      if imap_mail&.net_imap_mail.present?
        @net_imap_mail = imap_mail.net_imap_mail
      end
    end

    def mail
      @imap_mail&.mail
    end

    def bounced_mail_address
      bounced_email = bounced_mail_addresses

      raise Imap::MultiRecipientBounce if bounced_email.size > 1

      bounced_email.first
    end

    def bounced_mail_addresses
      original_tos = recipients_of_original_message
      mentioned_tos = mails_mentioned_in_notification

      if mentioned_tos.one?
        mentioned_tos
      elsif original_tos.any? && mentioned_tos.any?
        original_tos & mentioned_tos
      else
        original_tos
      end
    end

    private

    def recipients_of_original_message
      undelivered_message = mail.parts.find { |part| part.content_description == "Undelivered Message" }

      # return [] if undelivered_message.blank?

      ::Mail.new(undelivered_message.body).to
    end

    def mails_mentioned_in_notification
      mail
        .parts
        .find { |part| part.content_description == "Notification" }
        .to_s.scan(/\w+@\w+.\w+/).uniq
        .select { |email| Truemail.valid?(email, with: :regex) }
    end
  end
end
