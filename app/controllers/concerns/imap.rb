# encoding: utf-8

#  Copyright (c) 2021, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Imap
  extend ActiveSupport::Concern

  included do
    after_action :disconnect
  end

  private

  def imap
    if @imap.present?
      return @imap
    end

    connect(host, email, password)
  end

  def connect(host, email, password)
    imap = Net::IMAP.new(host, 993, true)
    imap.login(email, password)
    @imap = imap
  end

  def disconnect
    imap.close
    imap.disconnect
  end

  def fetch_by_uid(uid, mailbox_id = 'INBOX')
    imap.select(mailbox_id)
    imap.uid_fetch(uid, attributes)[0]
  end

  def move_by_uid(uid, from_mailbox_id, to_mailbox_id)
    imap.select(from_mailbox_id)
    imap.uid_move(uid, to_mailbox_id)
  end

  def delete_by_uid(uid, mailbox_id)
    imap.select(mailbox_id)
    # imap.uid_copy(uid, 'TRASH')
    imap.uid_store(uid, '+FLAGS', [:Deleted])
    imap.expunge
  end

  def fetch_all_from_mailbox(mailbox = 'INBOX')
    imap.select(mailbox)

    num_messages = imap.status(mailbox, ['MESSAGES'])['MESSAGES']
    if num_messages.positive?
      @imap.fetch(1..num_messages, attributes) || []
    else
      []
    end
  end

  def host
    ENV.fetch('RAILS_MAIL_RETRIEVER_CONFIG', 'imap.gmail.com')
  end

  def email
    ENV.fetch('USER_EMAIL', 'test.imap.hitobito@gmail.com')
  end

  def password
    ENV.fetch('USER_PASSWORD', 'test.imap')
  end

  def attributes
    %w(ENVELOPE UID BODYSTRUCTURE BODY[TEXT])
  end

end

