#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require "net/imap"

class Imap::Connector
  MAILBOXES = {inbox: "INBOX", spam: "Junk", failed: "Failed"}.with_indifferent_access.freeze

  def initialize
    @connected = false
    raise "no imap settings present" if imap_config.blank?
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
      @imap.uid_store(uid, "+FLAGS", [:Deleted])
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

  def fetch_mail_uids(mailbox)
    perform do
      select_mailbox(mailbox)
      @imap.uid_search(["ALL"])
    end
  end

  def fetch_mail_by_uid(uid, mailbox)
    perform do
      select_mailbox(mailbox)

      fetch_data = @imap.uid_fetch(uid, attributes)
      return nil if fetch_data.nil?

      Imap::Mail.build(fetch_data.first)
    end
  end

  def counts
    @counts ||= fetch_mailbox_counts
  end

  def config(key)
    imap_config[key]
  end

  private

  def count(mailbox)
    select_mailbox(mailbox)
    @imap.status(MAILBOXES[mailbox], ["MESSAGES"])["MESSAGES"]
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
    yield
  ensure
    disconnect
  end

  def connect
    return if @connected

    @imap = Net::IMAP.new(
      config(:address),
      port: config(:imap_port) || 993,
      ssl: config(:enable_ssl) || true
    )
    @imap.login(config(:user_name), config(:password))
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

  def imap_config
    @imap_config ||= read_imap_config
  end

  def read_imap_config
    if MailConfig.legacy?
      Settings.email.retriever.config
    else
      MailConfig.retriever_imap
    end
  end

  def attributes
    %w[ENVELOPE UID RFC822]
  end
end
