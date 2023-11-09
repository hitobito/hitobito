# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMail::Retriever

  LOG_PREFIX = 'BulkMail Retriever: '

  def perform
    return abort_imap_unavailable unless imap_server_available?

    mail_uids.each do |mail_uid|
      process_mail(mail_uid)
    end
  end

  private

  def process_mail(mail_uid)
    imap_mail = fetch_mail(mail_uid)

    validator = validator(imap_mail)

    if validator.processed_before?
      mail_processed_before!(imap_mail)
    end

    mail_log = create_mail_log(imap_mail)

    validate_and_process(imap_mail, mail_log, validator)

    delete_mail(mail_uid)
  end

  def validate_and_process(imap_mail, mail_log, validator)
    if validator.valid_mail?
      process_valid_mail(imap_mail, mail_log, validator)
    else
      log_info("Ignored invalid email from #{imap_mail.sender_email} " \
               "(invalid sender e-mail or no sender name present)")
    end
  end

  def process_valid_mail(imap_mail, mail_log, validator)
    mailing_list = assign_mailing_list(imap_mail)
    if mailing_list
      if imap_mail.auto_response?
        reject_auto_response(mail_log, imap_mail)
        return
      end

      process_mailing_list_mail(imap_mail, mail_log, validator, mailing_list)
    else
      mail_log.update!(status: :unknown_recipient)
      log_info("Ignored email from #{imap_mail.sender_email} " \
               "for unknown list #{imap_mail.original_to}")
    end
  end

  def reject_auto_response(mail_log, imap_mail)
    mail_log.update!(status: :auto_response_rejected)
    mail_log.message.destroy!
    log_info("Ignored auto response email from #{imap_mail.sender_email} " \
             "for list #{imap_mail.original_to}")
  end

  def process_mailing_list_mail(imap_mail, mail_log, validator, mailing_list)
    if imap_mail.list_bounce?
      bulk_mail = mail_log.message
      bounce_handler(imap_mail, bulk_mail, mailing_list).process
      return
    end

    process_non_reply_mail(imap_mail, mail_log, validator, mailing_list)
  end

  def process_non_reply_mail(imap_mail, mail_log, validator, mailing_list)
    bulk_mail = mail_log.message
    bulk_mail.update!(mailing_list: mailing_list, raw_source: imap_mail.raw_source)

    if validator.sender_allowed?(mailing_list)
      Messages::DispatchJob.new(bulk_mail).enqueue!
    else
      mail_log.update!(status: :sender_rejected)
      sender_rejected(imap_mail, bulk_mail)
    end
  end

  def abort_imap_unavailable
    imap_address = imap.config(:address)
    log_info("cannot connect to IMAP server #{imap_address}, terminating.")
  end

  def validator(mail)
    MailingLists::BulkMail::ImapMailValidator.new(mail)
  end

  def bounce_handler(imap_mail, bulk_mail, mailing_list)
    MailingLists::BulkMail::BounceHandler.new(imap_mail, bulk_mail, mailing_list)
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

  def create_mail_log(imap_mail)
    MailLog.create!(
      mail_hash: imap_mail.hash,
      status: :retrieved,
      mail_from: imap_mail.sender_email,
      message: create_bulk_mail_entry(imap_mail)
    )
  end

  def create_bulk_mail_entry(imap_mail)
    bulk_mail_class(imap_mail).create!(
      subject: encode_subject(imap_mail),
      state: :pending)
  end

  def encode_subject(imap_mail)
    return if imap_mail.subject.nil?

    subject = imap_mail.subject.dup[0,256]

    unless subject.encoding == 'UTF-8'
      subject.encode("UTF-8", invalid: :replace, undef: :replace)
    end
  end

  def bulk_mail_class(imap_mail)
    if imap_mail.list_bounce?
      Message::BulkMailBounce
    else
      Message::BulkMail
    end
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

  def imap_server_available?
    mail_uids != :connection_error
  end

  def mail_uids
    @mail_uids ||= fetch_mail_uids
  end

  def fetch_mail_uids
    imap.fetch_mail_uids(:inbox)
  rescue Errno::EADDRNOTAVAIL
    :connection_error
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
