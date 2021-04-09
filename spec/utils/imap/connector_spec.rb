#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
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
      expect(net_imap).to receive(:select).with('INBOX')
    end

    it 'fetches mail by uid' do
      expect(net_imap).to receive(:uid_fetch).with('42', anything).and_return([imap_mail_1])

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      mail = imap_connector.fetch_by_uid('42', 'INBOX')
      expect(mail).to eq(imap_mail_1.attr)
    end

    it 'fetches mail with invalid uid' do
      expect(net_imap).to receive(:uid_fetch).with('42', anything).and_return(nil)

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      mail = imap_connector.fetch_by_uid('42', 'INBOX')
      expect(mail).to be_nil
    end
  end

  describe '#move_by_uid' do
    before do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
    end

    it 'moves mail to existing mailbox' do
      expect(net_imap).to receive(:select).with('INBOX')
      expect(net_imap).to receive(:uid_move).with('42', 'FAILED')

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.move_by_uid('42', 'INBOX', 'FAILED')
    end

    it 'moves mail to not existing mailbox' do
      expect(net_imap).to receive(:select).with('INBOX').and_raise(no_mailbox_error)
      expect(net_imap).to receive(:uid_move).with('42', :invalid)

      expect(imap_connector).to receive(:create_if_missing)

      expect(net_imap).to receive(:disconnect)
      expect(net_imap).to receive(:close)

      imap_connector.move_by_uid('42', 'INBOX', :invalid)
    end
  end

  describe 'delete_by_uid' do
    it 'deletes mail' do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
      expect(net_imap).to receive(:select).with('INBOX')

      # expect(net_imap).to receive(:uid_copy).with(uid, 'TRASH')
      expect(net_imap).to receive(:uid_store).with('42', '+FLAGS', [:Deleted])
      expect(net_imap).to receive(:expunge)

      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      imap_connector.delete_by_uid('42', 'INBOX')
    end
  end

  describe '#fetch_mails' do
    before do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)
    end

    it 'fetches mails from a mailbox' do
      expect(net_imap).to receive(:select).with('INBOX')

      message_count = { 'MESSAGES' => imap_fetch_data.count }
      expect(net_imap).to receive(:status).with('INBOX', array_including("MESSAGES")).and_return(message_count)
      expect(net_imap).to receive(:fetch).with(1..2, anything).and_return(imap_fetch_data)

      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails('INBOX')

      mail1 = mails.first

      envelope = imap_mail_1.attr["ENVELOPE"]

      expect(mail1.uid).to eq('42')
      expect(mail1.subject).to be(envelope.subject)
      expect(mail1.date).to eq(Time.zone.utc_to_local(DateTime.parse(now.to_s)))
      expect(mail1.sender_email).to eq('Mailbox@sender.example.com')
      expect(mail1.sender_name).to eq('sender')
      expect(mail1.body).to eq('EMail Body')
    end

    it 'raises NoResponseError when mailbox does not exist' do
      expect(net_imap).to receive(:select).with(:not_existing).and_raise(no_mailbox_error)

      expect(net_imap).not_to receive(:status).with(:not_existing, array_including("MESSAGES"))
      expect(net_imap).not_to receive(:fetch).with(1..2, anything)

      expect(net_imap).not_to receive(:close)
      expect(net_imap).not_to receive(:disconnect)

      expect do
        imap_connector.fetch_mails(:not_existing)
      end.to raise_error(Net::IMAP::NoResponseError)
    end

    it 'fetch empty array from an empty mailbox' do
      expect(net_imap).to receive(:select).with('INBOX')

      expect(net_imap).to receive(:status).with('INBOX', array_including("MESSAGES")).and_return({ 'MESSAGES' => 0 })
      expect(net_imap).to receive(:fetch).with(1..2, anything).and_return([])

      expect(net_imap).to receive(:close)
      expect(net_imap).to receive(:disconnect)

      mails = imap_connector.fetch_mails('INBOX')

      expect(mails).to eq([])
    end
  end

  describe '#counts' do
    before do
      expect(Net::IMAP).to receive(:new).exactly(3).times.and_return(net_imap)
      expect(net_imap).to receive(:login).exactly(3).times
      expect(net_imap).to receive(:select).with('INBOX')
      expect(net_imap).to receive(:select).with('Junk')
      expect(net_imap).to receive(:select).with('Failed')
    end

    it 'counts number of mails in a mailbox' do
      expect(net_imap).to receive(:status).exactly(3).times.and_return({ 'MESSAGES' => 1 })

      expect(net_imap).to receive(:close).exactly(3).times
      expect(net_imap).to receive(:disconnect).exactly(3).times

      expect(imap_connector.counts['Failed']).to eq(1)
    end

    it 'counts number of all mailboxes' do
      expect(net_imap).to receive(:close).exactly(3).times
      expect(net_imap).to receive(:disconnect).exactly(3).times

      expect(net_imap).to receive(:status).exactly(3).times.and_return({ 'MESSAGES' => 1 })
      counts = imap_connector.counts

      expect(counts).to eq({"Failed"=>1, "INBOX"=>1, "Junk"=>1})
    end
  end

  describe '#create_if_failed' do
    it 'creates failed mailbox if non existent' do
      expect(Net::IMAP).to receive(:new).and_return(net_imap)
      expect(net_imap).to receive(:login)

      imap_connector.send(:connect)

      expect(net_imap).to receive(:create).with('Failed')
      expect(net_imap).to receive(:select).with('Failed')

      error = no_mailbox_error('Mailbox doesn\'t exist')

      imap_connector.send(:create_if_missing, 'Failed', error)
    end

    it 'raise error if non existent mailbox is not Failed' do
      error = no_mailbox_error('Mailbox doesn\'t exist')
      expect { imap_connector.send(:create_if_missing, 'INBOX', error) }.to raise_error(error)
    end

    it 'raise error if other error than no mailbox' do
      error = no_mailbox_error('Other NoResponse Error')
      expect { imap_connector.send(:create_if_missing, 'FAILED', error) }.to raise_error(error)
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
