# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingLists::BulkMailRetriever
  include MailingLists::ImapMails
  include MailingLists::BulkMail::RetrieverValidation

  attr_accessor :retrieve_count

  RETRIEVE_COUNT = 5

  def perform
    create_bulk_mail_messages

  end

  private

  def inbox_mail_uids
    @inbox_mail_uids ||= imap.fetch_mail_uids(:inbox)
  end

  def fetch_mail(uid)
    imap.fetch_mail_by_uid(uid, :inbox)
  end

  def create_bulk_mail_messages
    inbox_mail_uids.each do |uid|
      mail = fetch_mail(uid)

      next reject_mail if sender_id.nil? || !mailing_list_existent(mail)

      Message::BulkMail.create!(
        subject: mail.subject_utf8_encoded,
        text: mail.net_imap_mail.to_json,
        sender_id: sender_id
      )

      enqueue_dispatch
    end
  end

  def reject_mail
    # notify sender
  end

  def enqueue_dispatch
    # MailingLists::MailDispatchJob.new.enqueue!
  end
end
