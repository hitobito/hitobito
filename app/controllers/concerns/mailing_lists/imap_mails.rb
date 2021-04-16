# frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module MailingLists::ImapMails
  extend ActiveSupport::Concern

  def imap
    @imap ||= Imap::Connector.new
  end

  def valid_mailbox(mailbox)
    mailbox = mailbox.downcase
    Imap::Connector::MAILBOXES.keys.include?(mailbox) ? mailbox : 'inbox'
  end
end

