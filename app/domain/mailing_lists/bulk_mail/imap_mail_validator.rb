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
      required_header_present? && sender_email_valid?
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

    # TODO: adjust method
    def additional_sender?
      additional_senders = mailing_list.additional_sender.to_s
      list = additional_senders.split(/[,;]/).collect(&:strip).select(&:present?)
      sender_domain = sender_email.sub(/^[^@]*@/, '*@')
      # check if the domain is valid, if the sender is in the senders
      # list or if the domain is whitelisted
      list.include?(sender_email) ||
        (valid_domain?(sender_domain) && list.include?(sender_domain))
    end

    # VALIDATORS

    def required_header_present?
      valid_email?(receiver_from_header || receiver_from_mail)
    end

    def sender_email_valid?
      valid_email?(@mail.sender_email)
    end

    def valid_email?(email)
      email.present? && Truemail.valid?(email)
    end

    def valid_domain?(domain)
      domain !~ /^([a-z0-9]+(-[a-z0-9]+)*\.)+[a-z]{2,}$/
    end

    # GETTERS

    def receiver_from_mail
      @mail.email_to.presence
    end

    def receiver_from_header
      binding.pry
      first_header('X-Original-To').presence
    end

    def sender_email
      @mail.sender_email
    end

    def first_header(header_name)
      first_header = Array(@mail.mail.header[header_name]).first

      return nil if first_header.nil?

      first_header.value
    end
  end
end
