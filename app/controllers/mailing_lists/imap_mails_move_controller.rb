#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

include MailingLists::ImapMails

class MailingLists::ImapMailsMoveController < ApplicationController

  before_action :authorize_action

  # delegate :imap, :valid_mailbox, to: MailingLists::ImapMails

  def create
    raise Net::IMAP::BadResponseError unless param_from_mailbox != param_dst_mailbox

    param_ids.each do |id|
      imap.move_by_uid id, param_from_mailbox, param_dst_mailbox
    end

    redirect_to imap_mails_path(mailbox: mailbox)
  end

  private

  def authorize_action
    authorize!(:manage, Imap::Mail)
  end

  def param_ids
    params[:ids]&.split(',')&.map(&:to_i) || []
  end

  def mailbox
    validated_mailbox
  end

  def param_dst_mailbox
    validated_mailbox(:mail_dst)
  end

  def param_from_mailbox
    validated_mailbox(:from)
  end

  def validated_mailbox(mailbox_sym = :mailbox)
    mailbox = params[mailbox_sym]
    params[mailbox_sym] = valid_mailbox(mailbox)
  end
end
