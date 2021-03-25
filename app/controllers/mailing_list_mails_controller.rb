#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  Hitobito AG and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingListMailsController < ApplicationController

  authorize_resource MailingList::Mail, instance_name: 'mails'

  helper_method :mails, :mailbox, :mailbox_failed?, :mailboxes, :default_mailbox

  def index
    counts
    mails
  end

  def move
    return unless param_move_from_mailbox != param_move_to_mailbox

    param_ids.each do |id|
      imap.move_by_uid id, param_move_from_mailbox, param_move_to_mailbox
    end

    redirect_to mailing_list_mails_path(mailbox: param_move_from_mailbox)
  end

  def destroy
    param_ids.each do |id|
      imap.delete_by_uid(id, mailbox)
    end

    redirect_to mailing_list_mails_path(mailbox: mailbox)
  end

  private

  def imap
    @imap ||= ImapConnector.new
  end

  def default_mailbox
    'inbox'
  end

  def mails
    if @mails.present?
      return @mails
    end

    mails = imap.fetch_all(mailbox)
    mails = mails.map { |m| MailingList::Mail.new(imap_fetch_data: m, mailbox: mailbox) }

    mails = mails.sort { |a, b| a.date.to_i <=> b.date.to_i }
    mails = mails.reverse

    @mails = Kaminari.paginate_array(mails).page(params[:page])
  end

  def counts
    @counts ||= imap.counts
  end

  def param_uid
    params[:uid].to_i
  end

  def param_ids
    if params[:ids].empty?
      []
    else
      params[:ids].split(',').map { |id| id.to_i }
    end
  end

  def mailbox
    @mailbox ||= params.key?(:mailbox) ? params[:mailbox] : default_mailbox
  end

  def param_move_to_mailbox
    params[:to]
  end

  def param_move_from_mailbox
    params[:from]
  end

end
