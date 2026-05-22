# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

# This could also be called "MailingLists::CatchAllInbox::Handler".
#
# The main job is to retrieve all mails from the inbox and (mostly) enqueue
# them for later dispatch to the intended recipients. Sending is handled in
# a separate job and class.
#
# This whole class is the definition of a complexicated side-effect
class MailingLists::BulkMail::Retriever
  LOG_PREFIX = "BulkMail Retriever: "

  # The current implementation focusses on one short perform-methods that
  # goes over all mails and enqueues all mails after removing the invalid
  # one and the edge-cases.
  #
  # Each handler-method should either return the mail (mostly called
  # imap_mail) or move/delete the mail and return nil. This allows for
  # compaction between the stages.
  def perform
    return abort_imap_unavailable unless imap_server_available?

    mail_uids
      .filter_map { |uid| fetch_mail(uid) }
      .filter_map { |imap_mail| process_mail(imap_mail) }
      .empty? # nothing left to handle
  end

  def process_mail(imap_mail)
    valid_mail = reject_invalid_mail(imap_mail)
    return nil if valid_mail.blank?

    bulk_mail = prepare_bulk_mail(valid_mail)
    return nil if bulk_mail.blank?

    enqueue_for_multiplexing(valid_mail.uid, bulk_mail)
  end

  private

  def enqueue_for_multiplexing(uid, bulk_mail)
    Messages::DispatchJob.new(bulk_mail).enqueue!
    delete_mail(uid)
    nil
  end

  def prepare_bulk_mail(imap_mail)
    mail_log = create_mail_log(imap_mail)
    mailing_list = assign_mailing_list(imap_mail)

    return ignore_unknown_recipient(mail_log, imap_mail) if mailing_list.nil?
    return reject_auto_response(mail_log, imap_mail) if imap_mail.auto_response?
    return handle_list_bounce(mail_log, imap_mail, mailing_list) if imap_mail.list_bounce?

    bulk_mail = mail_log.message
    bulk_mail.update!(mailing_list: mailing_list, raw_source: imap_mail.raw_source)

    unless validator(imap_mail).sender_allowed?(mailing_list)
      return reject_forbidden_sender(mail_log, imap_mail, bulk_mail)
    end

    bulk_mail
  end

  def reject_invalid_mail(imap_mail)
    validator = validator(imap_mail)

    return mail_processed_before!(imap_mail) if validator.processed_before?
    return handle_too_big_mail!(imap_mail) if validator.mail_too_big?
    return handle_mail_without_path_header!(imap_mail.uid) if validator.return_path_header_nil?
    return handle_invalid_mail(imap_mail) unless validator.valid_mail?
    return handle_generic_bounce(imap_mail) if imap_mail.generic_bounce?

    imap_mail
  end

  def ignore_unknown_recipient(mail_log, imap_mail)
    mail_log.update!(status: :unknown_recipient)
    log_info("Ignored email from #{imap_mail.sender_email} " \
             "for unknown list #{imap_mail.original_to}")
    delete_mail(imap_mail.uid)
    nil
  end

  def reject_auto_response(mail_log, imap_mail)
    mail_log.update!(status: :auto_response_rejected)
    mail_log.message.destroy!
    log_info("Ignored auto response email from #{imap_mail.sender_email} " \
             "for list #{imap_mail.original_to}")

    delete_mail(imap_mail.uid)
    nil
  end

  def reject_forbidden_sender(mail_log, imap_mail, bulk_mail)
    mail_log.update!(status: :sender_rejected)
    list_email = bulk_mail.mailing_list.mail_address
    log_info("Rejecting email from #{imap_mail.sender_email} for list #{list_email}")
    MailingLists::BulkMail::SenderRejectedMessageJob.new(bulk_mail).enqueue!
    delete_mail(imap_mail.uid)
    nil
  end

  # Tooling and non happy-path methods

  def abort_imap_unavailable
    imap_address = imap.config(:address)
    log_info("cannot connect to IMAP server #{imap_address}, terminating.")

    false
  end

  def validator(mail)
    MailingLists::BulkMail::ImapMailValidator.new(mail)
  end

  def bounce_handler(bounce_mail, bulk_mail, mailing_list)
    MailingLists::BulkMail::BounceHandler.new(bounce_mail, bulk_mail, mailing_list)
  end

  def handle_list_bounce(mail_log, imap_mail, mailing_list)
    mail_log.update!(status: :bounce_rejected)

    bounce_mail = Imap::BounceMail.new(imap_mail)
    action_taken = bounce_handler(bounce_mail, mail_log.message, mailing_list).process

    if action_taken == :unknown
      move_mail_to_failed(imap_mail.uid)
    else
      delete_mail(imap_mail.uid)
    end

    nil
  end

  def handle_generic_bounce(imap_mail)
    bounce = Imap::BounceMail.new(imap_mail)
    action_taken = bounce_handler(bounce, nil, nil).perform_analyzed_action!

    if action_taken == :unknown
      move_mail_to_failed(imap_mail.uid)
    else
      delete_mail(imap_mail.uid)
    end

    nil
  end

  def assign_mailing_list(mail)
    mail_name = mail.original_to.split("@", 2).first
    MailingList.joins(:group).where(group: {archived_at: nil}).find_by(mail_name: mail_name)
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
      state: :pending
    )
  end

  def mail_processed_before!(mail)
    move_mail_to_failed(mail.uid)
    nil
  end

  def handle_too_big_mail!(imap_mail)
    sender, subject = imap_mail.sender_email, imap_mail.mail.subject
    FailureMailer.validation_checks(sender, subject).deliver_now
    delete_mail(imap_mail.uid)
    nil
  end

  def handle_mail_without_path_header!(mail_uid)
    move_mail_to_failed(mail_uid)
    Sentry.capture_message(
      "Mail header Return-Path is nil. Mail moved to :failed. See hitobito#3599 for more details.",
      extra: {
        mail_uid: mail_uid
      }
    )
    nil
  end

  def handle_invalid_mail(imap_mail)
    log_info("Ignored invalid email from #{imap_mail.sender_email} " \
             "(invalid sender e-mail or no sender name present)")
    delete_mail(imap_mail.uid)
    nil
  end

  def encode_subject(imap_mail)
    return if imap_mail.subject.nil?

    subject = imap_mail.subject.dup[0, 256]

    unless subject.encoding == "UTF-8"
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
