#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

include MailingLists::ImapMails

require 'net/imap'

class MailingLists::ImapMailsMoveController < ApplicationController

  before_action :authorize_action

  helper_method :mails

  def create
    raise mailbox_error unless param_from_mailbox != param_dst_mailbox

    perform_imap do
      list_param(:ids).each do |id|
        imap.move_by_uid id.to_i, param_from_mailbox, param_dst_mailbox
      end
    end

    redirect_to imap_mails_path(mailbox: mailbox), notice: moved_flash_message
  end

  private

  def mails
    @mails || []
  end

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def mailbox
    validated_mailbox
  end

  def param_dst_mailbox
    validated_mailbox(:mail_dst)
  end

  def param_from_mailbox
    validated_mailbox(:mailbox)
  end

  def validated_mailbox(mailbox_sym = :mailbox)
    mailbox = params[mailbox_sym]
    params[mailbox_sym] = valid_mailbox(mailbox)
  end

  def moved_flash_message
    server_error_message || I18n.t("#{i18n_prefix}.flash.moved")
  end
end

