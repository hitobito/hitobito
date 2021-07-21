#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

include MailingLists::ImapMails

require 'net/imap'

class MailingLists::ImapMailsMoveController < ApplicationController

  before_action :authorize_action

  helper_method :mailbox

  def create
    raise 'failed mails cannot be moved' if mailbox == :failed

    perform_imap do
      list_param(:ids).each do |id|
        imap.move_by_uid(id.to_i, mailbox, dst_mailbox)
      end
    end

    redirect_to imap_mails_path(mailbox: mailbox), notice: moved_flash_message
  end

  private

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def moved_flash_message
    server_error_message || I18n.t("#{i18n_prefix}.flash.moved", count: mails_move_count)
  end

  def mails_move_count
    list_param(:ids).count
  end
end

