# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::Retriever

  attr_accessor :retrieve_count

  def perform
    mail_uids.each do |mail_uid|
      process_mail(mail_uid)
    end
  end

  private

  def process_mail(mail_uid)
    mail = fetch_mail(mail_uid)

    validator = validator(mail)

    if validator.processed_before?
      mail_processed_before!
    end

    if validator.valid_mail?
      process_valid_mail(mail, validator)
    else
      # TODO maybe log entry?
    end

    delete_mail(mail)
  end

  def process_valid_mail(mail, validator)
    mailing_list = assign_mailing_list(mail)
    if mailing_list
      process_mailing_list_mail(mail, validator, mailing_list)
    else
      # TODO maybe log entry?
    end
  end

  def process_mailing_list_mail(mail, validator, mailing_list)
    bulk_mail_entry = create_bulk_mail_entry(mail, mailing_list)
    create_mail_log(mail)
    if validator.sender_allowed?(mailing_list)
      bulk_mail_entry.update!(raw_source: mail.raw_source)
      enqueue_dispatch(bulk_mail)
    else
      sender_not_allowed(mail, mailing_list)
    end
  end

  def validator(mail)
    MailingLists::BulkMail::ImapMailValidator.new(mail)
  end

  def sender_not_allowed(mail, mailing_list)
    # TODO enqueue bulk mail response mail job (sender not allowed)
  end

  def assign_mailing_list(mail)
    # MailingList.find_by
  end

  def create_bulk_mail_entry(mail)
    Message::BulkMail.create!(
      subject: mail.subject_utf8_encoded,
      text: mail.net_imap_mail.to_json,
      sender_id: sender_id)
  end

  def create_mail_log(mail)
    mail_log = MailLog.find_by(mail_hash: mail.hash)

    MailLog.create!(
      mail_hash: mail.hash,
      status: :retreived
    )
  end

  def enqueue_dispatch(bulk_mail)
    # Messages::DispatchJob.new.enqueue!
  end

  def enqueue_bulk_mail_response
    # Messages::BulkMailResponseJob.new.enqueue!
  end

  def abort_mail_processed_before
    # TODO move mail to failed folder
    raise MailProcessedBefore
  end

  # IMAP CONNECTOR

  def imap
    @imap ||= Imap::Connector.new
  end

  def mail_uids
    @mail_uids ||= imap.fetch_mail_uids(:inbox)
  end

  def delete_mail(uid)
    imap.delete_by_uid(uid)
  end

  def fetch_mail(uid)
    imap.fetch_mail_by_uid(uid, :inbox)
  end
end
