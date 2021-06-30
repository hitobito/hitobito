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

  let(:imap_mail_1) { new_mail(1) }
  let(:imap_mail_2) { new_mail(2, false) }
  let(:imap_fetch_data) { [imap_mail_1, imap_mail_2] }

  let(:fetch_attributes) { %w(ENVELOPE UID BODYSTRUCTURE BODY[TEXT] RFC822) }

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

  describe 'delete_by_uid' do
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
      expect(mail1.subject).to be(imap_mail_1.attr['ENVELOPE'].subject)
      expect(mail1.date).to eq(Time.zone.utc_to_local(DateTime.parse(now.to_s)))
      expect(mail1.sender_email).to eq('john@sender.example.com')
      expect(mail1.sender_name).to eq('sender')
      expect(mail1.body).to eq('SpaceX rocks!')
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

  def new_mail(id, text_body = true)
    Net::IMAP::FetchData.new(id, mail_attrs(text_body))
  end

  def mail_attrs(text_body)
    {
      'UID' => text_body ? '42' : '43',
      'RFC822' => text_body ? '' : new_html_message,
      'ENVELOPE' => new_envelope,
      'BODY[TEXT]' => text_body ? 'SpaceX rocks!' : 'Tesla rocks!',
      'BODYSTRUCTURE' => text_body ? new_text_body : new_html_body_type
    }
  end

  def new_envelope
    Net::IMAP::Envelope.new(
      now.to_s,
      'Testflight from 24.4.2021',
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
      'john',
      "#{name}.example.com"
    )
  end

  def new_text_body
    Net::IMAP::BodyTypeText.new('TEXT')
  end

  def new_html_body_type
    Net::IMAP::BodyTypeMultipart.new('MULTIPART')
  end

  def new_html_message
    Mail::Message.new("<h1>#{Faker::Lorem.sentences[0]}</h1>")
  end

end
