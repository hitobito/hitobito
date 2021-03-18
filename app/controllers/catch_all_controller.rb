#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class CatchAllController < ApplicationController

  include Imap

  skip_authorization_check

  def initialize
    super
    load_mailboxes
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

  def mailboxes
    @mailboxes ||= { INBOX: 'Inbox', SPAMMING: 'Spam', FAILED: 'Failed' }.freeze
  end

  def load_mailboxes
    mailboxes.each do |id, mailbox|
      instance_variable_set("@#{mailbox.to_s.downcase}_mails", map_to_catch_all_mail(fetch_all_from_mailbox(id.to_s), id.to_s))
    end
  end

  def param_uid
    params[:uid].to_i
  end

  def param_mailbox
    params[:mailbox]
  end

  def mails
    @mails ||= { inbox_mails: @inbox_mails, spam_mails: @spam_mails, failed_mails: @failed_mails }
  end

  def map_to_catch_all_mail(mails, mailbox)
    mails.map { |m| CatchAllMail.new(imap_fetch_data = m, mailbox = mailbox) }
  end

  def mail
    @mail ||= CatchAllMail.new(fetch_by_uid(param_uid, param_mailbox), param_mailbox)
  end

end
