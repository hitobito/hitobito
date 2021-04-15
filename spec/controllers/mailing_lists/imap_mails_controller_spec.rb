# frozen_string_literal: true

require 'spec_helper'

require 'net/imap'

describe MailingLists::ImapMailsController do

  let(:top_leader) { people(:top_leader) }

  let(:imap_connector) { double(:imap_connector) }

  let(:imap_mail_1) { new_mail }
  let(:imap_mail_2) { new_mail(false) }
  let(:imap_fetch_data) { [imap_mail_1, imap_mail_2] }

  let(:now) { Time.zone.now }

  context 'GET #index' do
    it 'lists all mails when admin' do
      # sign in
      sign_in(top_leader)

      # mock imap_connector for counts and mails
      expect(controller).to receive(:imap).twice.and_return(imap_connector)

      # counts
      expect(imap_connector).to receive(:counts).and_return(2)

      # mails
      expect(imap_connector).to receive(:fetch_mails).and_return(imap_fetch_data)

      # get #index
      get :index, params: { mailbox: :inbox }

      # success, is admin
      expect(response).to have_http_status(:success)

      mails = assigns(:mails)

      expect(mails.count).to eq(2)

      # length und werte
      # assigns(:mails).each do |_, mails|
      #   expect(mails).to be_instance_of(Array)
      #
      #   unless mails.empty?
      #     expect(mails).to all(be_instance_of(CatchAllMail))
      #   end
      # end
    end

    it 'changes mailbox param to inbox if no valid mailbox in params' do

    end
  end

  context 'PATCH move' do
    # source und dst mailbox auf MAILBOXES checken, wenn mailbox nicht existiert -> raise error
    it 'moves Mail to given mailbox' do
      patch :move, params: params_move
      expect(response).to have_http_status(:success)
    end

    xit 'redirects to index afterwards' do
      get :show, params: params
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'changes dst_mailbox param to valid mailbox' do
      expect do
        patch :move, params: params_move
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  context 'DELETE destroy' do
    it 'can be accessed as admin' do
      delete :destroy, params: params_delete
      expect(response).to have_http_status(:success)
    end

    xit 'redirects to index afterwards' do
      delete :destroy, params: params_delete
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'cannot be deleted by non-admin' do
      sign_in(people(:bottom_member))
      expect do
        delete :destroy, params: params
      end.to raise_error(CanCan::AccessDenied)
    end
  end

  def new_mail(text_body = true)
    imap_mail = Net::IMAP::FetchData.new(Faker::Number.number(digits: 1), text_body ? mail_attrs : mail_attrs_html)
    Imap::Mail.build(imap_mail)
  end

  def mail_attrs
    {
      'UID' => '42',
      'RFC822' => Faker::Lorem.sentences[0],
      'ENVELOPE' => new_envelope,
      'BODY[TEXT]' => 'SpaceX rocks!',
      'BODYSTRUCTURE' => new_text
    }
  end

  def mail_attrs_html
    {
      'UID' => '43',
      'RFC822' => new_html_message,
      'ENVELOPE' => new_envelope,
      'BODY[TEXT]' => 'EMail Body',
      'BODYSTRUCTURE' => new_html
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
      'john',
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
