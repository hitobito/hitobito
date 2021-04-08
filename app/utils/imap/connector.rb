# frozen_string_literal: true

#  Copyright (c) 2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class Imap::Connector

  def initialize
    @connected = false
    raise 'no imap settings present' unless settings_present?
  end

  def fetch_by_uid(uid, mailbox = 'inbox')
    perform do
      select_mailbox(mailbox)
      mail = @imap.uid_fetch(uid, attributes)
      mail.nil? ? nil : mail[0].attr
    end
  end

  def move_by_uid(uid, from_mailbox, to_mailbox)
    perform do
      select_mailbox(from_mailbox)
      @imap.uid_move(uid, to_mailbox)
    end
  end

  def delete_by_uid(uid, mailbox)
    perform do
      select_mailbox(mailbox)
      # imap.uid_copy(uid, 'TRASH')
      @imap.uid_store(uid, '+FLAGS', [:Deleted])
      @imap.expunge
    end
  end

  def fetch_mails(mailbox)
    perform do
      fetch_data = @imap.fetch(1..count(mailbox), attributes)
      fetch_data.map { |mail| Imap::Mail.new(mail) }
    end
  end

  def counts
    @counts ||= fetch_counts
  end

  private

  MAILBOXES = { inbox: 'INBOX', spam: 'Junk', failed: 'Failed' }.with_indifferent_access.freeze

  def count(mailbox)
    perform do
      select_mailbox mailbox
      @imap.status(mailbox, ['MESSAGES'])['MESSAGES']
    end
  end

  def fetch_counts
    counts = {}
    MAILBOXES.each do |_, m|
      counts[m] = count(m)
    end
    counts.with_indifferent_access
  end

  def perform
    already_connected = @connected
    connect unless already_connected
    result = yield
    disconnect unless already_connected
    result
  end

  def connect
    @imap = Net::IMAP.new(setting(:address), setting(:port), setting(:enable_ssl))
    @imap.login(setting(:user_name), setting(:password))
    @connected = true
  end

  def disconnect
    unless @imap.nil?
      @imap.close
      @imap.disconnect
      @connected = false
    end
  end

  def create_if_missing(mailbox, error)
    if (mailbox == MAILBOXES[:failed]) && error.response.data.text.include?("Mailbox doesn't exist")
      @imap.create(MAILBOXES[:failed])
      @imap.select(MAILBOXES[:failed])
    else
      raise error
    end
  end

  def select_mailbox(mailbox)
    @imap.select(mailbox)
  rescue Net::IMAP::NoResponseError => e
    create_if_missing(mailbox, e)
  end

  def setting(key)
    Settings.email.retriever.config.send(key)
  end

  def settings_present?
    !Settings.email.retriever.config.nil?
  end

  def attributes
    %w(ENVELOPE UID BODYSTRUCTURE BODY[TEXT] RFC822)
  end

end
