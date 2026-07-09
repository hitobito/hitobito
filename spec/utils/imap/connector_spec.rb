# frozen_string_literal: true

# Copyright (c) 2012-2022, Hitobito AG. This file is part of
# hitobito and licensed under the Affero General Public License version 3
# or later. See the COPYING file at the top-level directory or at
# https://github.com/hitobito/hitobito.

require "spec_helper"
require "net/imap"

describe Imap::Connector do
  include Mails::ImapMailsSpecHelper

  let(:net_imap) { double(:net_imap) }
  let(:imap_connector) { Imap::Connector.new }

  let(:imap_fetch_data_1) { imap_fetch_data }
  let(:imap_fetch_data_2) { imap_fetch_data(plain_body: false) }
  let(:imap_fetch_data_array) { [imap_fetch_data_1, imap_fetch_data_2] }
  let(:imap_fetched_uids) { [42, 43] }

  let(:fetch_attributes) { %w[ENVELOPE UID RFC822] }

  let(:imap_config) do
    {
      address: "imap.example.com",
      imap_port: 42_993,
      enable_ssl: true,
      user_name: "catch-all@example.com",
      password: "holly-secret"
    }
  end

  before do
    allow(MailConfig).to receive(:legacy?).and_return(false)
    allow(MailConfig).to receive(:retriever_imap).and_return(imap_config)

    expect(Net::IMAP).to receive(:new).and_return(net_imap)
    expect(net_imap).to receive(:login)
    expect(net_imap).to receive(:close)
    expect(net_imap).to receive(:disconnect)
  end

  describe "#move_by_uid" do
    it "moves mail to existing mailbox" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_move).with("42", "Failed")

      imap_connector.move_by_uid("42", :inbox, :failed)
    end

    it "moves mail to not existing mailbox" do
      expect(net_imap).to receive(:select).with("INBOX").and_raise(no_mailbox_error)
      expect(net_imap).to receive(:uid_move).with("42", nil)

      expect(imap_connector).to receive(:create_if_missing)

      imap_connector.move_by_uid("42", :inbox, :invalid)
    end
  end

  describe "#delete_by_uid" do
    it "deletes mail" do
      expect(net_imap).to receive(:select).with(nil)
      expect(net_imap).to receive(:uid_store).with("42", "+FLAGS", [:Deleted])
      expect(net_imap).to receive(:expunge)

      imap_connector.delete_by_uid("42", "INBOX")
    end
  end

  describe "#fetch_mails" do
    it "fetches paginated mails from inbox using uid search" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return([41, 42])

      # UIDs sorted descending: [42, 41]
      expect(net_imap).to receive(:uid_fetch).with([42, 41], fetch_attributes)
        .and_return(imap_fetch_data_array)

      result = imap_connector.fetch_mails(:inbox)

      expect(result[:total_count]).to eq(2)
      mail1 = result[:mails].first
      expect(mail1.uid).to eq("42")
      expect(mail1.subject).to be(imap_fetch_data_1.attr["ENVELOPE"].subject)
      expect(mail1.sender_email).to eq("john@sender.com")
      expect(mail1.sender_name).to eq("sender")
      expect(mail1.plain_text_body).to eq("SpaceX rocks!")
    end

    it "returns empty result if mailbox empty" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return([])

      result = imap_connector.fetch_mails(:inbox)
      expect(result).to eq({mails: [], total_count: 0})
    end

    it "creates failed mailbox if not existing" do
      expect(net_imap).to receive(:select).with("Failed")
        .and_raise(no_mailbox_error("Mailbox doesn't exist")).once

      expect(net_imap).to receive(:create).with("Failed")
      expect(net_imap).to receive(:select).with("Failed")
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return([])

      result = imap_connector.fetch_mails(:failed)
      expect(result).to eq({mails: [], total_count: 0})
    end

    it "raises error if junk mailbox does not exist" do
      expect(net_imap).to receive(:select).with("Junk")
        .and_raise(no_mailbox_error("Mailbox doesn't exist"))

      expect do
        imap_connector.fetch_mails(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe "#fetch_all_mails" do
    it "fetches all mails from inbox without pagination" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:status).with("INBOX", array_including("MESSAGES"))
        .and_return("MESSAGES" => 2)
      expect(net_imap).to receive(:fetch).with(1..2, fetch_attributes)
        .and_return(imap_fetch_data_array)

      mails = imap_connector.fetch_all_mails(:inbox)

      expect(mails.size).to eq(2)
      expect(mails.first.uid).to eq("42")
      expect(mails.first.plain_text_body).to eq("SpaceX rocks!")
    end

    it "returns empty array if mailbox empty" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:status).with("INBOX", array_including("MESSAGES"))
        .and_return("MESSAGES" => 0)

      mails = imap_connector.fetch_all_mails(:inbox)
      expect(mails).to eq([])
    end
  end

  describe "#fetch_mail_by_uid" do
    it "fetches mail by uid from inbox" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_fetch).with(42, fetch_attributes)
        .and_return([imap_fetch_data_1])

      mail = imap_connector.fetch_mail_by_uid(42, :inbox)

      expect(mail.uid).to eq("42")
      expect(mail.subject).to be(imap_fetch_data_1.attr["ENVELOPE"].subject)
      expect(mail.date.to_time).to be_within(2.seconds).of(Time.zone.utc_to_local(Time.zone.now))
      expect(mail.sender_email).to eq("john@sender.com")
      expect(mail.sender_name).to eq("sender")
      expect(mail.plain_text_body).to eq("SpaceX rocks!")
    end

    it "fetch empty array from an empty mailbox" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_fetch).with(42, fetch_attributes).and_return([])

      mails = imap_connector.fetch_mail_by_uid(42, :inbox)
      expect(mails).to eq(nil)
    end

    it "creates failed mailbox if not existing" do
      expect(net_imap).to receive(:select).with("Failed")
        .and_raise(no_mailbox_error("Mailbox doesn't exist")).once
      expect(net_imap).to receive(:select).with("Failed").once
      expect(net_imap).to receive(:create).with("Failed")
      expect(net_imap).to receive(:uid_fetch).with(43, fetch_attributes).and_return(nil)

      imap_connector.fetch_mail_by_uid(43, :failed)
    end

    it "raises error if junk mailbox does not exist" do
      expect(net_imap).to receive(:select).with("Junk")
        .and_raise(no_mailbox_error("Mailbox doesn't exist"))

      expect do
        imap_connector.fetch_mails(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe "#fetch_mail_uids" do
    it "fetches uids from inbox" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return(imap_fetched_uids)

      mail_uids = imap_connector.fetch_mail_uids(:inbox)

      expect(mail_uids.size).to eq(2)
      expect(mail_uids).to eq([42, 43])
    end

    it "fetch empty array from an empty mailbox" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return([])

      mail_uids = imap_connector.fetch_mail_uids(:inbox)
      expect(mail_uids).to eq([])
    end

    it "raises error if junk mailbox does not exist" do
      expect(net_imap).to receive(:select).with("Junk")
        .and_raise(no_mailbox_error("Mailbox doesn't exist"))

      expect do
        imap_connector.fetch_mail_uids(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe "#counts" do
    it "counts number of all mailboxes" do
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:select).with("Junk")
      expect(net_imap).to receive(:select).with("Failed")

      expect(net_imap).to receive(:status).with("INBOX", ["MESSAGES"]).and_return("MESSAGES" => 1)
      expect(net_imap).to receive(:status).with("Junk", ["MESSAGES"]).and_return("MESSAGES" => 1)
      expect(net_imap).to receive(:status).with("Failed", ["MESSAGES"]).and_return("MESSAGES" => 1)

      counts = imap_connector.counts

      expect(counts).to eq("failed" => 1, "inbox" => 1, "spam" => 1)
      expect(imap_connector.counts["failed"]).to eq(1)
    end
  end

  private

  def no_mailbox_error(text = "")
    response_text = Net::IMAP::ResponseText.new(nil, text)
    Net::IMAP::NoResponseError.new(Net::IMAP::TaggedResponse.new(nil, nil, response_text, nil))
  end
end
