#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::ImapMailsController < ApplicationController

  helper_method :mails, :mailbox

  before_action :authorize_action

  def index
    counts
    mails
  end

  def move
    return unless param_move_from_mailbox != param_move_to_mailbox

    param_ids.each do |id|
      imap.move_by_uid id, param_move_from_mailbox, param_move_to_mailbox
    end

    redirect_to imap_mails_path(mailbox: mailbox)
  end

  def destroy
    param_ids.each do |id|
      imap.delete_by_uid(id, mailbox)
    end

    redirect_to imap_mails_path(mailbox: mailbox)
  end

  private

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def imap
    @imap ||= Imap::Connector.new
  end

  def mails
    @mails ||= fetch_mails
  end

  def fetch_mails
    mails = imap.fetch_mails(mailbox)

    mails.sort! { |a, b| a.date.to_i <=> b.date.to_i }
    mails = mails.reverse

    Kaminari.paginate_array(mails).page(params[:page])
  end

  def counts
    imap.counts
  end

  def param_uid
    params[:uid].to_i
  end

  def param_ids
    params[:mail_ids]&.split(',')&.map(&:to_i) || []
  end

  def mailbox
    mailbox = params[:mailbox]
    params[:mailbox] = Imap::Connector::MAILBOXES.keys.include?(mailbox) ? mailbox : 'inbox'
  end

  def param_move_to_mailbox
    params[:mail_dst]
  end

  def param_move_from_mailbox
    params[:from]
  end
end
