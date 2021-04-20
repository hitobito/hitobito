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

  context 'GET #index' do
    it 'lists all mails when admin' do
      # sign in
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector)

      # mails
      expect(imap_connector).to receive(:fetch_mails).with('inbox').and_return(imap_mail_data)

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.view_context.mails

      expect(mails).to eq(imap_mail_data.reverse)

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

    it 'changes mailbox param to inbox if no valid mailbox in params' do
      # sign in
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector)

      # mails
      expect(imap_connector).to receive(:fetch_mails).with('inbox').and_return(imap_mail_data)

      get :index, params: { mailbox: 'invalid_mailbox' }

      mails = controller.view_context.mails

      expect(mails.count).to eq(2)
      expect(mails).to eq(imap_mail_data.reverse)
    end

    it 'raises error when mailserver not reachable' do
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector)

      # return no mails
      expect(imap_connector).to receive(:fetch_mails).with('inbox').and_return([])

      get :index, params: { mailbox: 'inbox' }

      expect(response).to have_http_status(:success)

      mails = controller.view_context.mails

      expect(assigns(:connected)).to eq(nil)
      expect(mails).to eq([])
    end
  end

  context 'DELETE #destroy' do
    it 'deletes specific mail from inbox' do
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector)

      expect(imap_connector).to receive(:delete_by_uid).with('42', :inbox)

      delete :destroy, params: { mailbox: 'inbox', id: '42' }

      expect(response).to redirect_to mailing_list_mails_path
      # expect(response).to have_http_status(:success)
    end

    it 'cannot be deleted by non-admin' do
      sign_in(people(:bottom_member))
      expect do
        delete :destroy, params: { mailbox: 'inbox', id: '42' }
      end.to raise_error(CanCan::AccessDenied)
    end

    it 'catches mail server error and displays flash notice' do
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).and_return(imap_connector)

      # return delete ids
      expect(imap_connector).to receive(:delete_by_uid).with('inbox').and_return([])

      expect do
        delete :destroy, params: { mailbox: 'unavailable_mailbox' }
      end.to_not raise_error # rescue_error(Net::IMAP::BadResponseError)

      # subject.stub(:delete_by_uid) { raise "boom" }
      # expect { subject.destroy }.to_not raise_error

      expect(flash[:notice]).to include 'Mailserver nicht verfügbar'

      expect(response).to have_http_status(:success)

      mails = controller.view_context.mails

      expect(assigns(:connected)).to eq(nil)
      expect(mails).to eq([])
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

end
