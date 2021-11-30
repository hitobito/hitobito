# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.



module MailingLists::BulkMail
  class ImapMailValidator

    def initialize(mail)
      @mail = mail
    end

    def valid_mail?
      # required_header_valid? && sender_email_valid?

      # does the mail have required header
      # is sender email valid?
    end

    def processed_before?

    end

    def sender_allowed?(mailing_list)
      return false unless valid_email?(sender_email)

      mailing_list.anyone_may_post? ||
        additional_sender? ||
        sender_group_email? ||
        sender_list_administrator? ||
        (mailing_list.subscribers_may_post? && sender_is_list_member?)
    end

    def valid_mailing_list_mail?
      mailing_list.present? && !mailing_list.group.archived?
    end

    private

    def valid_email?(email)
      email.present? && Truemail.valid?(email)
    end

    def additional_sender?
      return false if sender_email.blank?

      additional_senders = mailing_list.additional_sender.to_s
      list = additional_senders.split(/[,;]/).collect(&:strip).select(&:present?)
      sender_domain = sender_email.sub(/^[^@]*@/, '*@')
      # check if the domain is valid, if the sender is in the senders
      # list or if the domain is whitelisted
      list.include?(sender_email) ||
        (valid_domain?(sender_domain) && list.include?(sender_domain))
    end

    def valid_domain?(domain)
      domain !~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/
    end

    def sender_email
      @mail.sender_email
    end
  end
end
