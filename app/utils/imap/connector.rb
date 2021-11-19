#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'net/imap'

class Imap::Connector

  MAILBOXES = { inbox: 'INBOX', spam: 'Junk', failed: 'Failed' }.with_indifferent_access.freeze

  def initialize
    @connected = false
    raise 'no imap settings present' unless settings_present?
  end

  def move_by_uid(uid, from_mailbox, to_mailbox)
    perform do
      select_mailbox(from_mailbox)
      @imap.uid_move(uid, MAILBOXES[to_mailbox])
    end
  end

  def delete_by_uid(uid, mailbox)
    perform do
      select_mailbox(mailbox)
      @imap.uid_store(uid, '+FLAGS', [:Deleted])
      @imap.expunge
    end
  end

  def fetch_mails(mailbox)
    perform do
      mails_count = count(mailbox)
      return [] if mails_count.zero?

      fetch_data = @imap.fetch(1..mails_count, attributes)
      fetch_data.map { |mail| Imap::Mail.build(mail) }
    end
  end

  def fetch_mails_in_batches(mailbox, batch_size)
    batch = []

    perform do
      mails_count = count(mailbox)
      return [] if mails_count.zero?

      current_batch_start = 1
      current_batch_end = current_batch_start + batch_size

      if exceeds_mails_count?(current_batch_start, current_batch_end, mails_count)
        current_batch_end = batch_size - mails_count
      else
        current_batch_end += batch_size
      end

      fetch_data = @imap.fetch(current_batch_start..current_batch_end, attributes)
      batch << fetch_data.map { |mail| Imap::Mail.build(mail) }
    end

    batch
  end

  def counts
    @counts ||= fetch_mailbox_counts
  end

  private

  def count(mailbox)
    select_mailbox(mailbox)
    @imap.status(MAILBOXES[mailbox], ['MESSAGES'])['MESSAGES']
  end

  def fetch_mailbox_counts
    counts = {}
    perform do
      MAILBOXES.keys.each do |m|
        counts[m] = count(m)
      end
    end
    counts.with_indifferent_access
  end

  def perform
    connect
    result = yield
  ensure
    disconnect
    result
  end

  def connect
    return if @connected

    @imap = Net::IMAP.new(
      setting(:address), setting(:imap_port) || 993, setting(:enable_ssl) || true
    )
    @imap.login(setting(:user_name), setting(:password))
    @connected = true
  end

  def disconnect
    return unless @connected

    unless @imap.nil?
      @imap.close
      @imap.disconnect
      @connected = false
    end
  end

  def create_if_missing(mailbox, error)
    if (MAILBOXES[mailbox] == MAILBOXES[:failed]) &&
      error.response.data.text.include?("Mailbox doesn't exist")
      @imap.create(MAILBOXES[:failed])
      @imap.select(MAILBOXES[:failed])
    else
      raise error
    end
  end

  def select_mailbox(mailbox)
    @imap.select(MAILBOXES[mailbox])
  rescue Net::IMAP::NoResponseError => e
    create_if_missing(mailbox, e)
  end

  def setting(key)
    Settings.email.retriever.config.send(key)
  end

  def settings_present?
    Settings.email&.retriever&.config.present?
  end

  def attributes
    %w(ENVELOPE UID RFC822)
  end

  def exceeds_mails_count?(current_start, current_end, mails_count)
    current_end + current_start <= mails_count
  end
end
