# frozen_string_literal: true

require 'spec_helper'

require 'net/imap'

describe MailingLists::ImapMailsController do

  let(:top_leader) { people(:top_leader) }

  let(:imap_connector) { double(:imap_connector) }

  let(:imap_mail_1) { new_mail }
  let(:imap_mail_2) { new_mail(false) }
  let(:imap_mail_data) { [imap_mail_1, imap_mail_2] }

  let(:now) { Time.zone.now }

  before do
    email = double
    retriever = double
    config = 'address: imap.example.com, port: 995, user_name: catch-all@example.com, password: holly-secret'
    allow(Settings).to receive(:email).and_return(email)
    allow(email).to receive(:retriever).and_return(retriever)
    allow(retriever).to receive(:config).and_return(config)
  end

  context 'GET #index' do
    it 'lists all mails when admin' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)
      expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mail_data)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = assigns(:mails)

      expect(mails.count).to eq(2)

      mail1 = mails.last
      expect(mail1.uid).to eq('42')
      expect(mail1.subject).to be(imap_mail_1.subject)
      expect(mail1.date).to eq(Time.zone.utc_to_local(DateTime.parse(now.to_s)))
      expect(mail1.sender_email).to eq('john@sender.example.com')
      expect(mail1.sender_name).to eq('sender')
      expect(mail1.body).to eq('SpaceX rocks!')

      mail2 = mails.first
      expect(mail2.uid).to eq('43')
      expect(mail2.subject).to be(imap_mail_2.subject)
      expect(mail2.date).to eq(Time.zone.utc_to_local(DateTime.parse(now.to_s)))
      expect(mail2.sender_email).to eq('john@sender.example.com')
      expect(mail2.sender_name).to eq('sender')
      expect(mail2.body).to eq('<h1>Starship flies!</h1>')
    end

    it 'returns inbox mails if invalid mailbox given' do
      # sign in
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)
      expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mail_data)

      get :index, params: { mailbox: 'invalid_mailbox' }

      expect(response).to have_http_status(:success)
      mails = assigns(:mails)
      expect(mails.count).to eq(2)
    end

    it 'displays alert if mail server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)
      expect(imap_connector)
        .to receive(:fetch_mails)
        .with(:inbox)
        .and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.send(:mails)

      expect(mails.count).to eq(0)
      expect(flash[:alert])
        .to eq('Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut')
    end

    it 'denies access for non admin' do
      sign_in(people(:bottom_member))

      expect do
        get :index, params: { mailbox: 'inbox' }
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'DELETE #destroy' do
    it 'deletes specific mails from inbox' do
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector).twice

      expect(imap_connector).to receive(:delete_by_uid).with(42, :inbox)
      expect(imap_connector).to receive(:delete_by_uid).with(43, :inbox)

      delete :destroy, params: { mailbox: 'inbox', ids: '42, 43'}

      expect(flash[:notice]).to include 'Mail(s) erfolgreich gelöscht'
      expect(response).to redirect_to imap_mails_path(:inbox)
    end

    it 'cannot be deleted by non-admin' do
      sign_in(people(:bottom_member))
      expect do
        delete :destroy, params: { mailbox: 'inbox', ids: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'displays flash notice if mail server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector)
        .to receive(:delete_by_uid)
        .with(42, :inbox)
        .and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      delete :destroy, params: { mailbox: 'inbox', ids: '42' }

      expect(response).to have_http_status(:redirect)

      mails = controller.view_context.mails

      expect(mails.count).to eq(0)
      expect(flash[:notice])
        .to eq('Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut')
    end

  end

  private

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
