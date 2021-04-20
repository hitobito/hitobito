#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

include MailingLists::ImapMails

class MailingLists::ImapMailsController < ApplicationController

  helper_method :mails, :mailbox

  before_action :authorize_action

  def destroy
    # perform_imap do
      list_param(:ids).each do |id|
        # require 'pry'; binding.pry
        imap.delete_by_uid(id.to_i, mailbox)
      end
    # end
    redirect_to imap_mails_path(mailbox: mailbox), notice: destroy_flash_message
  end

  private

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def mails
    @mails ||= fetch_mails
  end

  def fetch_mails
    # perform_imap do
      mails = imap.fetch_mails(mailbox)
    # end
    return [] if mails == []

    mails.sort! { |a, b| a.date.to_i <=> b.date.to_i }
    mails = mails.reverse

    Kaminari.paginate_array(mails).page(params[:page])
  end

  def mailbox
    mailbox = params[:mailbox]
    params[:mailbox] = valid_mailbox(mailbox)
  end

  def destroy_flash_message
    I18n.t('mails.flash.deleted')
  end

  # catch mail server down exception
  def perform_imap(&block)
    begin
      yield
    rescue Net::IMAP::BadResponseError
      flash.notice('mails.flash.server_down')
    end
  end

end

