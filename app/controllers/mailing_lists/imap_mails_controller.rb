#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

include MailingLists::ImapMails

class MailingLists::ImapMailsController < ApplicationController

  helper_method :mails, :mailbox

  before_action :authorize_action

  # delegate :imap, :valid_mailbox, to: MailingLists::ImapMails

  def destroy
    list_param(:ids).each do |id|
      require 'pry'; binding.pry
      #check if id exists
      imap.delete_by_uid(id, mailbox)
    end

    redirect_to imap_mails_path(mailbox: mailbox)
    set_success_notice
  end

  private

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def mails
    @mails ||= fetch_mails
  end

  def fetch_mails
    mails = imap.fetch_mails(mailbox)

    return [] if mails == []

    mails.sort! { |a, b| a.date.to_i <=> b.date.to_i }
    mails = mails.reverse

    Kaminari.paginate_array(mails).page(params[:page])
  end

  def mailbox
    mailbox = params[:mailbox]
    params[:mailbox] = valid_mailbox(mailbox)
  end

end
