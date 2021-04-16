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

  context 'CREATE #move' do
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

      get :index, params: { mailbox: 'invalid_mailbox' }

      mails = assigns(:mails)

      expect(mails.count).to eq(2)
      expect(mails).to eq(imap_mail_data.reverse)


      patch :move, params: params_move
      expect(response).to have_http_status(:success)
    end

    it 'redirects to index afterwards' do
      get :show, params: params
      expect(response).to redirect_to mailing_list_mail_path
    end

    it 'permission check' do
      expect do
        patch :move, params: params_move
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

end
