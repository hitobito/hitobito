# frozen_string_literal: true

require 'spec_helper'

require 'net/imap'

describe MailingLists::ImapMailsController do
  include MailingLists::ImapMailsSpecHelper

  let(:top_leader) { people(:top_leader) }

  let(:imap_connector) { double(:imap_connector) }

  let(:imap_mail_1) { built_imap_mail }
  let(:imap_mail_2) { built_imap_mail(plain_body: false) }
  let(:imap_mail_data) { [imap_mail_1, imap_mail_2] }

  let(:now) { Time.zone.now }

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
      expect(mail1.date).to eq(Time.zone.utc_to_local(DateTime.parse(Time.now.to_s)))
      expect(mail1.sender_email).to eq('john@sender.com')
      expect(mail1.sender_name).to eq('sender')
      expect(mail1.plain_text_body).to eq('SpaceX rocks!')
      expect(mail1.multipart_body).to eq(nil)
      expect(mail1.hash.to_s.length).to eq(32)

      mail2 = mails.first
      expect(mail2.uid).to eq('43')
      expect(mail2.subject).to be(imap_mail_2.subject)
      expect(mail2.date).to eq(Time.zone.utc_to_local(DateTime.parse(Time.now.to_s)))
      expect(mail2.sender_email).to eq('john@sender.com')
      expect(mail2.sender_name).to eq('sender')
      expect(mail2.plain_text_body).to eq('This is just plain text!')
      expect(mail2.multipart_body).to eq('<h1>This is some Html</h1>')
      expect(mail2.hash.to_s.length).to eq(32)
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
        .to eq(['Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.', 'Authentication failed.'])
    end

    it 'denies access for non admin' do
      sign_in(people(:bottom_member))

      expect do
        get :index, params: { mailbox: 'inbox' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'displays flash if imap server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_raise(Errno::EADDRNOTAVAIL)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.send(:mails)

      expect(mails.count).to eq(0)
      expect(flash[:alert])
        .to eq(['Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.', 'Cannot assign requested address'])
    end

    it 'displays flash if imap server dns unresolvable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_raise(SocketError)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.send(:mails)

      expect(mails.count).to eq(0)
      expect(flash[:alert])
        .to eq(['Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.', 'SocketError'])
    end

    it 'displays flash if imap server credentials invalid' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.send(:mails)

      expect(mails.count).to eq(0)
      expect(flash[:alert])
        .to eq(['Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.', 'Authentication failed.'])
    end

    context 'invalid email envelopes' do
      render_views

      it 'renders when an envelope has no date header' do
        # sign in
        sign_in(top_leader)

        # Date header in the envelope is empty
        imap_mail_1.send(:envelope).date = ''

        # mock imap_connector
        allow(controller).to receive(:imap).and_return(imap_connector)
        expect(imap_connector).to receive(:fetch_mails).with(:inbox).and_return(imap_mail_data)
        allow(imap_connector).to receive(:counts).and_return(inbox: 2)

        get :index, params: { mailbox: 'inbox' }

        expect(response).to have_http_status(:success)
      end
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

      expect(flash[:notice]).to include '2 Mails erfolgreich gelöscht'
      expect(response).to redirect_to imap_mails_path(:inbox)
    end

    it 'cannot be deleted by non-admin' do
      sign_in(people(:bottom_member))
      expect do
        delete :destroy, params: { mailbox: 'inbox', ids: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'displays flash notice if imap server not reachable' do
      sign_in(top_leader)

      # mock imap_connector
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector)
        .to receive(:delete_by_uid)
              .with(42, :inbox)
              .and_raise(Net::IMAP::NoResponseError, ImapErrorDataDouble)

      delete :destroy, params: { mailbox: 'unavailable_mailbox', ids: '42' }

      expect(response).to have_http_status(:redirect)

      expect(flash[:notice])
        .to eq(['Verbindung zum Mailserver nicht möglich, bitte versuche es später erneut.', 'Authentication failed.'])
    end
  end

  private

  # and_raise only accepts either String or Module
  # so creating a double with a Module
  module ImapErrorDataDouble
    Data = Struct.new(:text)
    def self.data
      data = Data.new('Authentication failed.')
      data
    end
  end

end
