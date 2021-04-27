#  frozen_string_literal: true

#  Copyright (c) 2012-2021, Hitobito AG. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

require 'net/imap'

describe MailingLists::ImapMailsMoveController do

  let(:top_leader) { people(:top_leader) }

  let(:imap_connector) { double(:imap_connector) }

  let(:imap_mail_1) { new_mail }
  let(:imap_mail_2) { new_mail(false) }
  let(:imap_mail_data) { [imap_mail_1, imap_mail_2] }

  let(:now) { Time.zone.now }

  context 'PATCH #create' do
    it 'moves Mail to given mailbox' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector).twice

      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :failed)
      expect(imap_connector).to receive(:move_by_uid).with(43, :inbox, :failed)

      patch :create, params: { mailbox: 'inbox', ids: '42,43', dst_mailbox: 'failed' }

      expect(flash[:notice]).to include 'Mail(s) erfolgreich verschoben'
      expect(response).to have_http_status(:found)
      expect(response).to redirect_to imap_mails_path
    end

    it 'returns inbox if given mailbox is invalid' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :inbox)

      patch :create, params: { mailbox: 'inbox', ids: '42', dst_mailbox: 'invalid_mailbox' }

      expect(flash[:notice]).to include 'Mail(s) erfolgreich verschoben'
      expect(response).to have_http_status(:found)
      expect(response.location).to eq('http://test.host/mailing_lists/imap_mails/inbox')
    end

    it 'does not allow non-admins to move mails' do
      sign_in(people(:bottom_member))
      expect do
        patch :create, params: { mailbox: 'inbox', ids: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'displays flash notice if mail server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector)
        .to receive(:move_by_uid)
        .with(42, :inbox, :failed)
        .and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      patch :create, params: { mailbox: 'inbox', ids: '42', dst_mailbox: 'failed' }

      expect(response).to have_http_status(:redirect)

      expect(flash[:notice])
        .to eq('Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut')
    end

    it 'cannot move mails from failed mailbox' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector).never

      expect do
        patch :create, params: { mailbox: 'failed', ids: '42', mail_dst: 'inbox' }
      end.to raise_error('failed mails cannot be moved')
    end  

  end

  def new_mail(text_body = true)
    imap_mail = Net::IMAP::FetchData.new(Faker::Number.number(digits: 1), mail_attrs(text_body))
    Imap::Mail.build(imap_mail)
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
    html_message = Mail::Message.new
    html_message.body('<h1>Starship flies!</h1>')
    html_message.text_part = ''
    html_message
  end

  # and_raise only accepts either String or Module
  # so creating a double with a Module
  module ImapErrorDataDouble
    Data = Struct.new(:text)
    def self.data
      data = Data.new('failure!')
      data
    end
  end

end
