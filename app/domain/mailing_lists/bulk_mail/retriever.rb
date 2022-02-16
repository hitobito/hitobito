# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::Retriever

  LOG_PREFIX = 'BulkMail Retriever: '

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
      mail_processed_before!(mail)
    end

    mail.mail_log = create_mail_log(mail)

    if validator.valid_mail?
      process_valid_mail(mail, validator)
    else
      log_info("Ignored invalid email from #{mail.sender_email}")
    end

    delete_mail(mail_uid)
  end

  def process_valid_mail(mail, validator)
    mailing_list = assign_mailing_list(mail)
    if mailing_list
      process_mailing_list_mail(mail, validator, mailing_list)
    else
      mail.mail_log.update!(status: :unknown_recipient)
      log_info("Ignored email from #{mail.sender_email} for unknown list #{mail.original_to}")
    end
  end

  def process_mailing_list_mail(mail, validator, mailing_list)
    bulk_mail = mail.mail_log.message
    bulk_mail.update!(mailing_list: mailing_list)

    if validator.sender_allowed?(mailing_list)
      bulk_mail.update!(raw_source: mail.raw_source)
      Messages::DispatchJob.new(bulk_mail).enqueue!
    else
      mail.mail_log.update!(status: :sender_rejected)
      sender_rejected(mail, bulk_mail)
    end
  end

  def validator(mail)
    MailingLists::BulkMail::ImapMailValidator.new(mail)
  end

  def sender_rejected(mail, bulk_mail)
    list_email = bulk_mail.mailing_list.mail_address
    log_info("Rejecting email from #{mail.sender_email} for list #{list_email}")
    MailingLists::BulkMail::SenderRejectedMessageJob.new(bulk_mail).enqueue!
  end

  def assign_mailing_list(mail)
    mail_name = mail.original_to.split('@', 2).first
    MailingList.joins(:group).where(group: { archived_at: nil }).find_by(mail_name: mail_name)
  end

  def create_mail_log(mail)
    MailLog.create!(
      mail_hash: mail.hash,
      status: :retrieved,
      mail_from: mail.sender_email,
      message: create_bulk_mail_entry(mail)
    )
  end

  def create_bulk_mail_entry(mail)
    Message::BulkMail.create!(
      subject: mail.subject,
      state: :pending
    )
  end

  def mail_processed_before!(mail)
    move_mail_to_failed(mail.uid)
    mail_log = MailLog.find_by(mail_hash: mail.hash)
    raise MailingLists::BulkMail::MailProcessedBeforeError, mail_log
  end

  def log_info(text)
    logger.info LOG_PREFIX + text
  end

  def logger
    Delayed::Worker.logger || Rails.logger
  end

  # IMAP CONNECTOR

  def imap
    @imap ||= Imap::Connector.new
  end

  def mail_uids
    @mail_uids ||= imap.fetch_mail_uids(:inbox)
  end

  def delete_mail(uid)
    imap.delete_by_uid(uid, :inbox)
  end

  def fetch_mail(uid)
    imap.fetch_mail_by_uid(uid, :inbox)
  end

  def move_mail_to_failed(uid)
    imap.move_by_uid(uid, :inbox, :failed)
  end
end
