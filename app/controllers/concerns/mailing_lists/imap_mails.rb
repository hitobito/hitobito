# frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

module MailingLists::ImapMails
  extend ActiveSupport::Concern

  IMAP_SERVER_ERRORS = [Net::IMAP::ResponseError,
                        Errno::EADDRNOTAVAIL,
                        SocketError].freeze

  private

  def mailbox(param_name = :mailbox)
    mailbox = params[param_name]
    mailbox = mailbox.to_s.downcase
    mailboxes.include?(mailbox) ? mailbox.to_sym : :inbox
  end

  def dst_mailbox
    mailbox(:dst_mailbox)
  end

  def imap
    @imap ||= Imap::Connector.new
  end

  def mailboxes
    Imap::Connector::MAILBOXES.keys
  end

  def perform_imap
    return if @server_error

    yield
  rescue *IMAP_SERVER_ERRORS => e
    @server_error = true
    @server_error_message = e.message
  end

  def i18n_prefix
    'mailing_lists.imap_mails'
  end

  def server_error_message
    if @server_error
      [I18n.t("#{i18n_prefix}.flash.server_error"), @server_error_message]
    end
  end

end
