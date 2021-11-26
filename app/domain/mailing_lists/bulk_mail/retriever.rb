# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::Retriever

  attr_accessor :retrieve_count

  RETRIEVE_COUNT = 5

  def perform
    mail_uids.each do |mail_uid|
      process_mail(mail_uid)
    end
  end

  private

  def process_mail(mail_uid)
    mail = fetch_mail(mail_uid)

    # @validator = MailingLists::BulkMail::MailValidator.new(mail, mailing_list)

    # validate mail attrs?
    # return unless validator.mail_valid?(mail)

    create_mail_log(mail)
    assign_mailing_list(mail)
    enqueue_dispatch
  end

  def assign_mailing_list(mail)



    # @mailing_list = MailingList.find_by
  end

  def imap
    @imap ||= Imap::Connector.new
  end

  def mail_uids
    @inbox_mail_uids ||= imap.fetch_mail_uids(:inbox)
  end

  def fetch_mail(uid)
    imap.fetch_mail_by_uid(uid, :inbox)
  end

  # def create_bulk_mail_messages
  #   mail_uids.each do |uid|
  #     mail = fetch_mail(uid)
  #
  #     next reject_not_allowed unless retriever_validator.sender_allowed?
  #
  #     Message::BulkMail.create!(
  #       subject: mail.subject_utf8_encoded,
  #       text: mail.net_imap_mail.to_json,
  #       sender_id: sender_id
  #     )
  #
  #     enqueue_dispatch
  #   end
  # end

  def create_mail_log(mail)
    mail_log = MailLog.find_by(mail_hash: mail.hash)

    raise MailProcessedBefore if mail_log.present?

    MailLog.create!(
      mail_hash: mail.hash,
      status: :retreived
    )
  end

  def reject_not_allowed
    # notify sender
  end

  def enqueue_dispatch
    # Messages::DispatchJob.new.enqueue!
  end

  def enqueue_bulk_mail_response
    # Messages::BulkMailResponseJob.new.enqueue!
  end
end
