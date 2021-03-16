#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class MailsController < ApplicationController

  after_action :disconnect

  skip_authorization_check

  class Mailbox
    def initialize(name, id)
      @name = name
      @id = id
    end

    attr_reader :name
    attr_reader :id
  end

  INBOX = Mailbox.new('Inbox', 'INBOX')
  FAILED = Mailbox.new('Failed', 'FAILED')
  SPAM = Mailbox.new('Spam', 'SPAMMING')

  def initialize
    super
    @mailboxes = [INBOX, FAILED, SPAM].freeze
  end

  def index
    mails
  end

  def show
    mail
  end

  def update
    move_by_uid param_uid, param_mailbox, params[:move_to]
    redirect_to mails_path
  end

  def destroy
    delete_by_uid(param_uid, param_mailbox)
    redirect_to mails_path
  end

  private

  def param_uid
    params[:uid].to_i
  end

  def param_mailbox
    params[:mailbox]
  end

  def imap
    if @imap.present?
      return @imap
    end

    imap = Net::IMAP.new('imap.gmail.com', 993, true)
    imap.login(email, password)
    @imap ||= imap
  end

  def disconnect
    imap.close
    imap.disconnect
  end

  def mails
    @mails ||= { inbox_mails: inbox_mails, spam_mails: spam_mails, failed_mails: failed_mails }
  end

  def failed_mails
    @failed_mails ||= mailbox_mails(FAILED)
  end

  def spam_mails
    @spam_mails ||= mailbox_mails(SPAM)
  end

  def inbox_mails
    @inbox_mails ||= mailbox_mails(INBOX)
  end

  def mailbox_mails(mailbox = INBOX)
    imap.select(mailbox.id)

    num_messages = imap.status(mailbox.id, ['MESSAGES'])['MESSAGES']
    mails = if num_messages.positive?
              @imap.fetch(1..num_messages, attributes) || []
            else
              []
            end

    mails.map { |m| CatchAllMail.new(imap_fetch_data=m, mailbox=mailbox.id) }

  end

  def mail
    @mail ||= fetch_by_uid(param_uid, param_mailbox)
  end

  def fetch_by_uid(uid, mailbox_id = INBOX.id)
    imap.select(mailbox_id)
    fetch_data = imap.uid_fetch(uid, attributes)[0]
    CatchAllMail.new(fetch_data, mailbox_id)
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
