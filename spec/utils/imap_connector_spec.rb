# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

require 'net/imap'

describe ImapConnector do

  let(:net_imap) { double(:net_imap) }
  let(:imap_connector) { ImapConnector.new }

  let(:mailboxes) { { inbox: 'INBOX', failed: 'Failed' }.with_indifferent_access.freeze }
  let(:mailbox_inbox) { 'INBOX' }
  let(:mailbox_failed) { 'Failed' }

  let(:imap_fetch_data) { FetchData.new }
  let(:uid) { 42 }

  before do
    stub_const('ImapConnector::MAILBOXES', mailboxes)
  end

  context 'connection' do

    it 'connects' do
      expect_connect

      imap_connector.send(:connect)
      expect(imap_connector.instance_variable_get(:@connected)).to be_truthy
    end

    it 'disconnects' do
      expect_connect

      imap_connector.send(:connect)

      expect_disconnect
      imap_connector.send(:disconnect)

      expect(imap_connector.instance_variable_get(:@connected)).to be_falsey
      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to be_nil
    end

    it 'performs' do
      expect_perform

      result = imap_connector.send(:perform) { 42 }
      expect(result).to eq(42)
    end

    it 'connects once with nested perform' do
      expect_perform

      result = imap_connector.send(:perform) do
        imap_connector.send(:perform) { 42 }
      end
      expect(result).to eq(42)

    end

  end

  describe '#select' do

    before do
      expect_connect
      imap_connector.send(:connect)
    end

    it 'selects mailbox' do
      expect_select mailbox_inbox
      imap_connector.send(:select_mailbox, :inbox)
      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to eq(mailbox_inbox)
    end

    it 'does not select again if already selected' do
      expect_select mailbox_inbox
      imap_connector.send(:select_mailbox, :inbox)
      imap_connector.send(:select_mailbox, :inbox)
      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to eq(mailbox_inbox)
    end

    it 'selects another mailbox' do
      expect_select mailbox_inbox
      imap_connector.send(:select_mailbox, :inbox)
      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to eq(mailbox_inbox)

      expect_select mailbox_failed
      imap_connector.send(:select_mailbox, :failed)
      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to eq(mailbox_failed)
    end

    it 'create failed mailbox if not existent when selecting' do

      error = no_mailbox_error

      expect(net_imap).to receive(:select).with(mailbox_failed).and_raise(error)
      expect(imap_connector).to receive(:create_if_failed).with(mailbox_failed, error)

      imap_connector.send(:select_mailbox, :failed)

      expect(imap_connector.instance_variable_get(:@selected_mailbox)).to eq(mailbox_failed)
    end

  end

  describe '#create_if_failed' do

    it 'creates failed mailbox if non existent' do
      expect_connect
      imap_connector.send(:connect)

      expect(net_imap).to receive(:create).with(mailbox_failed)
      expect(net_imap).to receive(:select).with(mailbox_failed)

      error = no_mailbox_error('Mailbox doesn\'t exist')

      imap_connector.send(:create_if_failed, mailbox_failed, error)
    end

    it 'raise error if non existent mailbox is not Failed' do
      error = no_mailbox_error('Mailbox doesn\'t exist')
      expect { imap_connector.send(:create_if_failed, mailbox_inbox, error) }.to raise_error(error)
    end

    it 'raise error if other error than no mailbox' do
      error = no_mailbox_error('Other NoResponse Error')
      expect { imap_connector.send(:create_if_failed, mailbox_failed, error) }.to raise_error(error)
    end

  end

  context 'public methods:' do

    before do
      expect_perform
      expect_select mailbox_inbox
    end

    describe '#fetch_by_uid' do

      it 'fetches mail by uid' do
        expect(net_imap).to receive(:uid_fetch).with(uid, anything).and_return([imap_fetch_data])

        mail = imap_connector.fetch_by_uid(uid, :inbox)
        expect(mail).to eq(imap_fetch_data.attr)
      end

      it 'fetches mail with invalid uid' do
        expect(net_imap).to receive(:uid_fetch).with(uid, anything).and_return(nil)

        mail = imap_connector.fetch_by_uid(uid, :inbox)
        expect(mail).to be_nil
      end

    end

    describe '#move_by_uid' do

      it 'moves mail' do
        expect(net_imap).to receive(:uid_move).with(uid, mailbox_failed)

        imap_connector.move_by_uid(uid, :inbox, :failed)
      end

    end

    describe '#delete_by_uid' do

      it 'deletes mail' do
        # expect(net_imap).to receive(:uid_copy).with(uid, 'TRASH')
        expect(net_imap).to receive(:uid_store).with(uid, '+FLAGS', [:Deleted])
        expect(net_imap).to receive(:expunge)

        imap_connector.delete_by_uid(uid, :inbox)
      end

    end

    describe '#fetch_all' do

      it 'fetch all mail from a mailbox' do
        expect(net_imap).to receive(:status).with(mailbox_inbox, ['MESSAGES']).and_return({ 'MESSAGES' => 2 })
        expect(net_imap).to receive(:fetch).with(1..2, anything).and_return([imap_fetch_data, imap_fetch_data])

        mails = imap_connector.fetch_all(:inbox)

        expect(mails).to be_an_instance_of(Array)
        expect(mails).to all(be_an_instance_of(Hash))
        expect(mails).to all(eq(imap_fetch_data.attr))
      end

      it 'fetch empty array from an empty mailbox' do
        expect(net_imap).to receive(:status).with(mailbox_inbox, ['MESSAGES']).and_return({ 'MESSAGES' => 0 })

        mails = imap_connector.fetch_all(:inbox)

        expect(mails).to eq([])
      end

    end

    describe '#count' do

      it 'counts number of mails in a mailbox' do
        expect(net_imap).to receive(:status).with(mailbox_inbox, ['MESSAGES']).and_return({ 'MESSAGES' => 1 })
        expect(imap_connector.count(:inbox)).to eq(1)
      end

      it 'counts number of all mailboxes' do
        expect_select mailbox_failed

        expect(net_imap).to receive(:status).twice.and_return({ 'MESSAGES' => 1 })
        counts = imap_connector.counts

        expect(counts).to eq({ 'inbox' => 1, 'failed' => 1 })
      end

    end

  end

  def expect_connect(number = 1)
    expect(Net::IMAP).to receive(:new).and_return(net_imap)
    expect(net_imap).to receive(:login).exactly(number).times
  end

  def expect_disconnect(number = 1)
    expect(net_imap).to receive(:close).exactly(number).times
    expect(net_imap).to receive(:disconnect).exactly(number).times
  end

  def expect_perform
    expect_connect
    expect_disconnect
  end

  def expect_select(mailbox)
    expect(net_imap).to receive(:select).with(mailbox)
  end

  def no_mailbox_error(text = '')
    response_text = Net::IMAP::ResponseText.new(nil, text)
    Net::IMAP::NoResponseError.new(Net::IMAP::TaggedResponse.new(nil, nil, response_text, nil))
  end

  class FetchData
    attr_reader :attr

    def initialize(uid = 0)
      @attr = { 'ENVELOPE' => 'test', 'UID' => uid, 'BODYSTRUCTURE' => '', 'BODY[TEXT]' => '' }
    end
  end

end
