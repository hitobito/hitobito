#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

require 'net/imap'

describe Imap::Connector do
  include MailingLists::ImapMailsHelper

  let(:net_imap) { double(:net_imap) }
  let(:imap_connector) { Imap::Connector.new }

  let(:imap_fetch_data_1) { new_imap_fetch_data }
  let(:imap_fetch_data_2) { new_imap_fetch_data(false) }
  let(:imap_fetch_data) { [imap_fetch_data_1, imap_fetch_data_2] }
  let(:imap_fetched_uids) { [42, 43] }

  let(:fetch_attributes) { %w(ENVELOPE UID RFC822) }

  before do
    email = double
    retriever = double
    config = double('config',
                    address: 'imap.example.com',
                    imap_port: 995,
                    enable_ssl: true,
                    user_name: 'catch-all@example.com',
                    password: 'holly-secret')
    allow(Settings).to receive(:email).and_return(email)
    allow(email).to receive(:retriever).and_return(retriever)
    allow(retriever).to receive(:config).and_return(config)
  end

  describe '#move_by_uid' do
    it 'moves mail to existing mailbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # move
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:uid_move).with('42', "Failed")

      # disconnect
      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.move_by_uid('42', :inbox, :failed)
    end

    it 'moves mail to not existing mailbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # move
      expect(net_imap).to receive(:select).with("INBOX").and_raise(no_mailbox_error)
      expect(net_imap).to receive(:uid_move).with('42', nil)

      expect(imap_connector).to receive(:create_if_missing)

      # disconnect
      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.move_by_uid('42', :inbox, :invalid)
    end
  end

  describe '#delete_by_uid' do
    it 'deletes mail' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select
      expect(net_imap).to receive(:select).with(nil)

      # expect(net_imap).to receive(:uid_copy).with(uid, 'TRASH')
      expect(net_imap).to receive(:uid_store).with('42', '+FLAGS', [:Deleted])
      expect(net_imap).to receive(:expunge)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      imap_connector.delete_by_uid('42', 'INBOX')
    end
  end

  describe '#fetch_mails' do
    it 'fetches mails from inbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # count
      expect(net_imap).to receive(:select).with('INBOX')
      expect(net_imap).to receive(:status).with('INBOX', array_including('MESSAGES')).and_return({ 'MESSAGES' => 2 })

      # fetch
      expect(net_imap).to receive(:fetch).with(1..2, fetch_attributes).and_return(imap_fetch_data)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails(:inbox)

      mail1 = mails.first

      # check mail content
      expect(mail1.uid).to eq('42')
      expect(mail1.subject).to be(imap_fetch_data_1.attr['ENVELOPE'].subject)
      expect(mail1.date).to eq(Time.zone.utc_to_local(DateTime.parse(Time.now.to_s)))
      expect(mail1.sender_email).to eq('john@sender.example.com')
      expect(mail1.sender_name).to eq('sender')
      expect(mail1.plain_text_body).to eq('SpaceX rocks!')
    end

    it 'fetch empty array from an empty mailbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # count
      expect(net_imap).to receive(:select).with("INBOX")
      expect(net_imap).to receive(:status).with("INBOX", array_including('MESSAGES')).and_return('MESSAGES' => 0)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails(:inbox)
      expect(mails).to eq([])
    end

    it 'creates failed mailbox if not existing' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select mailbox
      expect(net_imap).to receive(:select).with('Failed').and_raise(no_mailbox_error("Mailbox doesn't exist")).once

      # create mailbox
      expect(net_imap).to receive(:create).with('Failed')

      # count mails and select mailbox again
      expect(net_imap).to receive(:select).with('Failed')
      expect(net_imap).to receive(:status).with('Failed', array_including('MESSAGES')).and_return('MESSAGES' => 0)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      imap_connector.fetch_mails(:failed)
    end

    it 'raises error if junk mailbox does not exist' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select
      expect(net_imap).to receive(:select).with('Junk').and_raise(no_mailbox_error("Mailbox doesn't exist"))

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      expect do
        imap_connector.fetch_mails(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe '#fetch_mail_by_uid' do
    it 'fetches mail by uid from inbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select inbox
      expect(net_imap).to receive(:select).with('INBOX')

      # fetch
      expect(net_imap).to receive(:uid_fetch).with(42, fetch_attributes).and_return([imap_fetch_data_1])

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mail = imap_connector.fetch_mail_by_uid(42, :inbox)

      # check mail content
      expect(mail.uid).to eq('42')
      expect(mail.subject).to be(imap_fetch_data_1.attr['ENVELOPE'].subject)
      expect(mail.date).to eq(Time.zone.utc_to_local(DateTime.parse(Time.now.to_s)))
      expect(mail.sender_email).to eq('john@sender.example.com')
      expect(mail.sender_name).to eq('sender')
      expect(mail.plain_text_body).to eq('SpaceX rocks!')
    end

    it 'fetch empty array from an empty mailbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select inbox
      expect(net_imap).to receive(:select).with('INBOX')

      # fetch
      expect(net_imap).to receive(:uid_fetch).with(42, fetch_attributes).and_return(nil)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mail_by_uid(42, :inbox)
      expect(mails).to eq(nil)
    end

    it 'creates failed mailbox if not existing' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select nonexistent failed mailbox
      expect(net_imap).to receive(:select).with('Failed').and_raise(no_mailbox_error("Mailbox doesn't exist")).once

      # select existent failed mailbox
      expect(net_imap).to receive(:select).with('Failed').once

      # create mailbox
      expect(net_imap).to receive(:create).with('Failed')

      # fetch
      expect(net_imap).to receive(:uid_fetch).with(43, fetch_attributes).and_return(nil)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      imap_connector.fetch_mail_by_uid(43, :failed)
    end

    it 'raises error if junk mailbox does not exist' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select
      expect(net_imap).to receive(:select).with('Junk').and_raise(no_mailbox_error("Mailbox doesn't exist"))

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      expect do
        imap_connector.fetch_mails(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe '#fetch_mail_uids' do
    it 'fetches uids from inbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select inbox
      expect(net_imap).to receive(:select).with('INBOX')

      # fetch
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return(imap_fetched_uids)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mail_uids = imap_connector.fetch_mail_uids(:inbox)

      # check fetched content
      expect(mail_uids.size).to eq(2)
      expect(mail_uids).to eq([42, 43])
    end

    it 'fetch empty array from an empty mailbox' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select inbox
      expect(net_imap).to receive(:select).with('INBOX')

      # fetch
      expect(net_imap).to receive(:uid_search).with(["ALL"]).and_return([])

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mail_uids = imap_connector.fetch_mail_uids(:inbox)
      expect(mail_uids).to eq([])
    end

    it 'raises error if junk mailbox does not exist' do
      # connect
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      # select
      expect(net_imap).to receive(:select).with("Junk").and_raise(no_mailbox_error("Mailbox doesn't exist"))

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      expect do
        imap_connector.fetch_mail_uids(:spam)
      end.to raise_error(Net::IMAP::NoResponseError)
    end
  end

  describe '#counts' do
    it 'counts number of all mailboxes' do
      # connect
      expect(Net::IMAP).to receive(:new).once.and_return(net_imap)
      expect(net_imap).to receive(:login).once

      # select
      expect(net_imap).to receive(:select).with('INBOX')
      expect(net_imap).to receive(:select).with('Junk')
      expect(net_imap).to receive(:select).with('Failed')

      # count each mailbox
      expect(net_imap).to receive(:status).with('INBOX', ['MESSAGES']).and_return('MESSAGES' => 1)
      expect(net_imap).to receive(:status).with('Junk', ['MESSAGES']).and_return('MESSAGES' => 1)
      expect(net_imap).to receive(:status).with('Failed', ['MESSAGES']).and_return('MESSAGES' => 1)

      # disconnect
      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      counts = imap_connector.counts

      expect(counts).to eq('failed' => 1, 'inbox' => 1, 'spam' => 1)
      expect(imap_connector.counts['failed']).to eq(1)
    end
  end

  private

  def no_mailbox_error(text = '')
    response_text = Net::IMAP::ResponseText.new(nil, text)
    Net::IMAP::NoResponseError.new(Net::IMAP::TaggedResponse.new(nil, nil, response_text, nil))
  end

end
