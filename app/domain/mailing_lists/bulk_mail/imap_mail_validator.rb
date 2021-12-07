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
      mail_log = MailLog.find_by(mail_hash: @mail.hash)
      mail_log.present?
    end

    def sender_allowed?(mailing_list)
      sender_allowed_for?(mailing_list) || allowed_by_group?(mailing_list)
    end

    private

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

    def sender_allowed_for?(mailing_list)
      mailing_list.anyone_may_post? ||
        may_post_as_subscriber?(mailing_list) ||
        additional_sender?(mailing_list) ||
        list_administrator?(mailing_list)
    end

    def may_post_as_subscriber?(mailing_list)
      mailing_list.subscribers_may_post? && sender_list_member?(mailing_list)
    end

    def sender_list_member?(mailing_list)
      mailing_list.people.where(id: possible_senders.select(:id)).exists?
    end

    def allowed_by_group?(mailing_list)
      group = mailing_list.group
      sender_group_email?(group) || additional_sender_for?(group)
    end

    def sender_group_email?(group)
      group.email == @mail.sender_email
    end

    def additional_sender_for?(group)
      group.additional_emails.collect(&:email).include?(@mail.sender_email)
    end

    def list_administrator?(mailing_list)
      possible_senders.any? do |sender|
        Ability.new(sender).can?(:update, mailing_list)
      end
    end

    def additional_sender?(mailing_list)
      additional_senders = mailing_list.additional_sender.to_s
      list = additional_senders.split(/[,;]/).collect(&:strip).select(&:present?)
      sender_domain = sender_email.sub(/^[^@]*@/, '*@')
      # check if the domain is valid, if the sender is in the senders
      # list or if the domain is whitelisted
      list.include?(sender_email) ||
        (valid_domain?(sender_domain) && list.include?(sender_domain))
    end

    def receiver_from_mail
      @mail.email_to.presence
    end

    def receiver_from_header
      first_header('X-Original-To').presence
    end

    def sender_email
      @mail.sender_email
    end

    def first_header(header_name)
      first_header = Array(@mail.mail.header[header_name]).first

      first_header.try(:value)
    end

    def possible_senders
      Person
        .joins('LEFT JOIN additional_emails ON people.id = additional_emails.contactable_id' \
               " AND additional_emails.contactable_type = '#{Person.sti_name}'")
        .where('people.email = :email OR additional_emails.email = :email',
               email: @mail.sender_email)
        .distinct
    end
  end
end
