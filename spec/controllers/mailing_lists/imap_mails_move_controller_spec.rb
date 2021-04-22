# frozen_string_literal: true

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
    # source und dst mailbox auf MAILBOXES checken, wenn mailbox nicht existiert -> raise error
    it 'moves Mail to given mailbox' do
      # sign in
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).twice.and_return(imap_connector)

      # counts
      expect(imap_connector).to receive(:counts).and_return(2)

      # mails
      expect(imap_connector).to receive(:fetch_mails).and_return(imap_mail_data)

      patch :create, params: { ids: '42, 43' }

      mails = assigns(:mails)

      expect(mails.count).to eq(2)
      expect(mails).to eq(imap_mail_data.reverse)

      expect(imap_connector).to receive(:move_by_uid).with(42, :inbox, :inbox)
      expect(imap_connector).to receive(:move_by_uid).with(43, :inbox, :inbox)

      patch :create, params: { ids: '42, 43' }

      expect(flash[:notice]).to include 'Mail(s) erfolgreich verschoben'
      expect(response).to have_http_status(:success)
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'raises error if given mailbox is invalid' do

    end

    it 'displays flash notice if mail server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector)
        .to receive(:move_by_uid)
        .with(42, :inbox, :inbox)
        .and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      patch :create, params: { mailbox: 'inbox', ids: '42' }

      expect(response).to have_http_status(:redirect)

      mails = controller.view_context.mails

      expect(mails.count).to eq(0)
      expect(flash[:notice])
        .to eq('Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut')
    end 

    it 'does not allow non-admins to move mails' do
      sign_in(people(:bottom_member))
      expect do
        patch :create, params: { mailbox: 'inbox', ids: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    # bereits gelöschtes Email sollte nicht verschoben werden können
    #
    # checken ob mailserver aktiv ist.

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
