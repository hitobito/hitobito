#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class MailsController < SimpleCrudController

  def initialize
    super
  end

  def index
    mails
  end

  private

  def move_mails(range, from_mailbox, to_mailbox)
    imap.select(from_mailbox)
    imap.move(range, to_mailbox)
  end

  def mails
    @mails ||= { inbox_mails: inbox_mails, spam_mails: spam_mails, failed_mails: failed_mails }
  end

  def fetch_by_uid(uid, mailbox = 'INBOX')
    imap.select(mailbox)
    imap.uid_fetch(uid, attributes)
  end

  def failed_mails
    @failed_mails ||= entries('FAILED')
  end

  def spam_mails
    @spam_mails ||= entries('SPAMMING')
  end

  def inbox_mails
    @inbox_mails ||= entries
  end

  def imap
    if @imap.present?
      return @imap
    end

    imap = Net::IMAP.new('imap.gmail.com', 993, true)
    imap.login(email, password)
    @imap ||= imap
  end

  def entry
    @entry ||= find_entry
  end

  def entries(mailbox = 'INBOX')
    imap.select(mailbox)

    num_messages = @imap.responses['UIDNEXT'][-1]
    @imap.fetch(1..num_messages, attributes) || []
  end

  def find_entry
    fetch_by_uid(params[:uid], params[:mailbox])
  end

  def email
    ENV.fetch('USER_EMAIL', 'test.imap.hitobito@gmail.com')
  end

  def password
    ENV.fetch('USER_PASSWORD', 'test.imap')
  end

  def attributes
    %w(ENVELOPE UID)
  end
end
