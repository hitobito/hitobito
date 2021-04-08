# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

require 'net/imap'

describe Imap::Connector do

  let(:net_imap) { double(:net_imap) }

  let(:imap_connector) { Imap::Connector.new }

  let(:now) { Time.zone.now }

  let(:imap_mail_1) { new_mail }

  let(:imap_mail_2) { new_mail(false) }

  let(:imap_fetch_data) { [imap_mail_1, imap_mail_2] }

  describe '#fetch_by_uid' do
    before do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
      expect(net_imap).to receive(:select).with(:inbox)
    end

    it 'fetches mail by uid' do
      expect(net_imap).to receive(:uid_fetch).with('42', anything).and_return([imap_mail_1])

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      mail = imap_connector.fetch_by_uid('42', :inbox)
      expect(mail).to eq(imap_mail_1.attr)
    end

    it 'fetches mail with invalid uid' do
      expect(net_imap).to receive(:uid_fetch).with('42', anything).and_return(nil)

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      mail = imap_connector.fetch_by_uid('42', :inbox)
      expect(mail).to be_nil
    end
  end

  describe '#move_by_uid' do
    before do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
      expect(net_imap).to receive(:select).with(:inbox)
    end

    it 'moves mail' do
      expect(net_imap).to receive(:uid_move).with('42', :failed)

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.move_by_uid('42', :inbox, :failed)
    end

    it 'create failed mailbox if not existent when selecting' do
      expect(net_imap).to receive(:select).with(:failed).and_raise(error)
      expect(imap_connector).to receive(:create_if_failed).with(:failed, error)

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.send(:select_mailbox, :failed)
    end
  end

  describe 'delete_by_uid' do
    it 'deletes mail' do
      # expect(net_imap).to receive(:uid_copy).with(uid, 'TRASH')
      expect(net_imap).to receive(:uid_store).with(uid, '+FLAGS', [:Deleted])
      expect(net_imap).to receive(:expunge)

      imap_connector.delete_by_uid(uid, :inbox)
    end
  end

  describe '#fetch_mails' do
    it 'fetches mails from a mailbox' do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
      expect(net_imap).to receive(:select).with(:inbox)

      message_count = { 'MESSAGES' => imap_fetch_data.count }
      expect(net_imap).to receive(:status).with(:inbox, array_including("MESSAGES")).and_return(message_count)
      expect(net_imap).to receive(:fetch).with(1..2, anything).and_return(imap_fetch_data)

      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails(:inbox)
      mail1 = mails.first

      envelope = imap_fetch_data.first.attr["ENVELOPE"]

      expect(mail1.uid).to be('42')
      expect(mail1.subject).to be(envelope.subject)
      expect(mail1.date).to eq(now)
      expect(mail1.sender_email).to eq('sender@sender.example.com')
      expect(mail1.sender_name).to eq('sender')
      # Body als konstaner wert
      expect(mail1.body).to be(imap_fetch_data.first.attr['BODY[TEXT]'])

      expect(imap_connector.instance_variable_get(:@connected)).to be_falsey
    end

    it 'refuses to fetch mails from non existent mailbox' do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      expect(net_imap).to receive(:select).with(:not_existing).and_raise(error)

      expect(net_imap).not_to receive(:status).with(:not_existing, array_including("MESSAGES"))
      expect(net_imap).not_to receive(:fetch).with(1..2, anything)

      expect(net_imap).not_to receive(:close)
      expect(net_imap).not_to receive(:disconnect)

      expect do
        imap_connector.fetch_mails(:not_existing)
      end.to raise_error(Net::IMAP::NoResponseError)
    end

    it 'fetch empty array from an empty mailbox' do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
      expect(net_imap).to receive(:select).with(:inbox)

      expect(net_imap).to receive(:status).with(:inbox, array_including("MESSAGES")).and_return({ 'MESSAGES' => 0 })
      expect(net_imap).to receive(:fetch).with(1..2, anything).and_return([])

      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails(:inbox)

      expect(mails).to eq([])
    end
  end

  describe '#counts' do
    it 'counts number of mails in a mailbox' do
      expect(net_imap).to receive(:status).with(:inbox, ['MESSAGES']).and_return({ 'MESSAGES' => 1 })
      expect(imap_connector.count(:inbox)).to eq(1)
    end

    it 'counts number of all mailboxes' do
      expect_select :failed

      expect(net_imap).to receive(:status).twice.and_return({ 'MESSAGES' => 1 })
      counts = imap_connector.counts

      expect(counts).to eq({ 'inbox' => 1, 'failed' => 1 })
    end
  end


  describe '#create_if_failed' do

    it 'creates failed mailbox if non existent' do
      expect_connect
      imap_connector.send(:connect)

      expect(net_imap).to receive(:create).with(:failed)
      expect(net_imap).to receive(:select).with(:failed)

      error = no_mailbox_error('Mailbox doesn\'t exist')

      imap_connector.send(:create_if_failed, :failed, error)
    end

    it 'raise error if non existent mailbox is not Failed' do
      error = no_mailbox_error('Mailbox doesn\'t exist')
      expect { imap_connector.send(:create_if_failed, :inbox, error) }.to raise_error(error)
    end

    it 'raise error if other error than no mailbox' do
      error = no_mailbox_error('Other NoResponse Error')
      expect { imap_connector.send(:create_if_failed, :failed, error) }.to raise_error(error)
    end

  end

  def no_mailbox_error(text = '')
    response_text = Net::IMAP::ResponseText.new(nil, text)
    Net::IMAP::NoResponseError.new(Net::IMAP::TaggedResponse.new(nil, nil, response_text, nil))
  end

  def new_mail(text_body = true)
    Net::IMAP::FetchData.new(Faker::Number.number(digits: 1), text_body ? mail_attrs : mail_attrs_html)
  end

  def mail_attrs
    {
      "UID" => '42',
      "RFC822" => Faker::Lorem.sentences[0],
      "ENVELOPE" => new_envelope,
      "BODY[TEXT]" => "EMail Body",
      "BODYSTRUCTURE" => new_text
    }
  end

  def mail_attrs_html
    {
      "UID" => '43',
      "RFC822" => new_html_message,
      "ENVELOPE" => new_envelope,
      "BODY[TEXT]" => "EMail Body",
      "BODYSTRUCTURE" => new_html
    }
  end

  def new_envelope
    Net::IMAP::Envelope.new(
      now.to_s,
      Faker::Lorem.word,
      [new_address('from')],
      [new_address('sender')],
      [new_address('reply_to')],
      [new_address('to')]
    )
  end

  def new_address(name)
    Net::IMAP::Address.new(
      name,
      nil,
      'Mailbox',
      "#{name}.example.com"
    )
  end

  def new_text
    Net::IMAP::BodyTypeText.new('TEXT')
  end

  def new_html
    Net::IMAP::BodyTypeMultipart.new('MULTIPART')
  end

  def new_html_message
    Mail::Message.new("<h1>#{Faker::Lorem.sentences[0]}</h1>")
  end

end
