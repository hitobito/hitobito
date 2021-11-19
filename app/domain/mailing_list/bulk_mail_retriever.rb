# frozen_string_literal: true

# Copyright (c) 2012-2021, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

class MailingList::BulkMailRetriever

  include MailingLists::ImapMails

  attr_accessor :retrieve_count, :imap_connector

  RETRIEVE_COUNT = 5

  def perform
    create_bulk_mail_messages

  end

  def reject_not_existing
    # mail abozugehörig?
  end

  private

  def mails
    @mails ||= imap.fetch_mails(:inbox)
  end

  def create_bulk_mail_messages
    mails.each do |mail|
      Message::BulkMail.create!(
        subject: Faker::Book.genre,
        mail_log: log
      )
    end
  end

end
