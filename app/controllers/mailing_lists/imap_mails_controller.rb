#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class MailingLists::ImapMailsController < ApplicationController

  include MailingLists::ImapMails

  helper_method :mails, :mailbox, :counts

  before_action :authorize_action

  def index
    perform_imap do
      @mails = fetch_mails
      binding.pry
    end

    flash.now[:alert] = server_error_message
  end

  def destroy
    perform_imap do
      list_param(:ids).each do |id|
        imap.delete_by_uid(id.to_i, mailbox)
      end
    end

    redirect_to imap_mails_path(mailbox: mailbox), notice: destroy_flash_message
  end

  private

  def mails
    @mails || []
  end

  def fetch_mails
    mails = imap.fetch_mails(mailbox)

    mails.sort! { |a, b| a.date.to_i <=> b.date.to_i }
    mails = mails.reverse

    Kaminari.paginate_array(mails).page(params[:page].to_i)
  end

  def counts
    fetch_counts || {}
  end

  def fetch_counts
    perform_imap do
      imap.counts
    end
  end

  def destroy_flash_message
    server_error_message || I18n.t("#{i18n_prefix}.flash.deleted", count: mails_delete_count)
  end

  def mails_delete_count
    list_param(:ids).count
  end

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

end
