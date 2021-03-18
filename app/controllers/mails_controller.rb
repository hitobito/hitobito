#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class MailsController < ApplicationController

  include Imap

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

  def mails
    @mails ||= { inbox_mails: inbox_mails, spam_mails: spam_mails, failed_mails: failed_mails }
  end

  def failed_mails
    @failed_mails ||= map_to_catch_all_mail(fetch_all_from_mailbox(FAILED.id), 'FAILED')
  end

  def spam_mails
    @spam_mails ||= map_to_catch_all_mail(fetch_all_from_mailbox(SPAM.id), 'SPAM')
  end

  def inbox_mails
    @inbox_mails ||= map_to_catch_all_mail(fetch_all_from_mailbox(INBOX.id), 'INBOX')
  end

  def map_to_catch_all_mail(mails, mailbox)
    mails.map { |m| CatchAllMail.new(imap_fetch_data = m, mailbox = mailbox) }
  end

  def mail
    @mail ||= CatchAllMail.new(fetch_by_uid(param_uid, param_mailbox), param_mailbox)
  end

end
